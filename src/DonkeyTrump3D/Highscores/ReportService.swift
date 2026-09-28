import Foundation

enum ReportReason: String, CaseIterable, Codable, Sendable {
    case offensiveName, impersonation, personalInformation, other
    var label: String {
        switch self {
        case .offensiveName: "Offensive name"
        case .impersonation: "Impersonation"
        case .personalInformation: "Personal information"
        case .other: "Other concern"
        }
    }
}
struct ReportSubmission: Codable, Sendable, Equatable {
    let reportId: UUID
    let entryId: UUID
    let reason: ReportReason
}
struct ReportReceipt: Decodable, Sendable, Equatable {
    let reportId: UUID
    let status: String
    let createdAtUtc: Date?
    let acknowledgedAtUtc: Date?
    let resolvedAtUtc: Date?
    let disposition: String?
    let alreadyPending: Bool?
    var message: String {
        if alreadyPending == true { return "Your earlier report is still pending. Its status is shown here." }
        switch disposition {
        case "removed": return "The entry has been removed."
        case "removedAndBlocked": return "The entry has been removed and its installation blocked from publishing."
        case "legacyRemoved", "starterRemoved": return "The entry has been removed."
        case "noAction": return "The owner reviewed this report and left the entry unchanged."
        case "dismissedSpam": return "The owner classified this report as spam and closed it."
        default: return status == "acknowledged" ? "The owner has received your report." : "Report saved. The owner checks reports every working day."
        }
    }
    func validate() throws {
        guard reportId != HighscoreRules.zeroID, ["pending", "acknowledged", "resolved"].contains(status) else { throw HighscoreServiceError.invalidResponse }
        if status == "resolved" {
            guard resolvedAtUtc != nil, let disposition,
                  ["removed", "removedAndBlocked", "legacyRemoved", "starterRemoved", "noAction", "dismissedSpam"].contains(disposition) else { throw HighscoreServiceError.invalidResponse }
        } else {
            guard createdAtUtc != nil, resolvedAtUtc == nil, disposition == nil,
                  (status == "acknowledged") == (acknowledgedAtUtc != nil) else { throw HighscoreServiceError.invalidResponse }
        }
    }
}
protocol ReportService: Sendable {
    func submit(_ report: ReportSubmission) async throws -> ReportReceipt
    func status(_ id: UUID) async throws -> ReportReceipt
}
struct UnavailableReportService: ReportService {
    func submit(_ report: ReportSubmission) async throws -> ReportReceipt { throw HighscoreServiceError.unavailable }
    func status(_ id: UUID) async throws -> ReportReceipt { throw HighscoreServiceError.unavailable }
}
final class URLSessionReportService: ReportService, @unchecked Sendable {
    private let configuration: HighscoreConfiguration
    private let credential: any InstallationCredentialProviding
    private let session: URLSession
    init(configuration: HighscoreConfiguration, credential: any InstallationCredentialProviding = InstallationCredentialStore.shared,
         sessionConfiguration: URLSessionConfiguration? = nil) {
        self.configuration = configuration; self.credential = credential
        let transport = sessionConfiguration ?? .ephemeral
        transport.waitsForConnectivity = false; transport.timeoutIntervalForRequest = 8; transport.timeoutIntervalForResource = 8
        transport.urlCache = nil; transport.httpCookieStorage = nil; transport.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: transport, delegate: HighscoreRedirectPolicy(), delegateQueue: nil)
    }
    deinit { session.invalidateAndCancel() }
    func submit(_ report: ReportSubmission) async throws -> ReportReceipt { try await execute(report: report, id: report.reportId) }
    func status(_ id: UUID) async throws -> ReportReceipt { try await execute(report: nil, id: id) }
    private func execute(report: ReportSubmission?, id: UUID) async throws -> ReportReceipt {
        let endpoint = report == nil ? configuration.reportEndpoint.appendingPathComponent(id.uuidString.lowercased()) : configuration.reportEndpoint
        var request = URLRequest(url: endpoint)
        // Credential failures occur before any possible network write.
        request.setValue(try await credential.authorization(), forHTTPHeaderField: "Authorization")
        request.httpMethod = report == nil ? "GET" : "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let report {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(report)
        }
        do {
            let (bytes, raw) = try await session.bytes(for: request)
            guard let response = raw as? HTTPURLResponse, response.url == endpoint else { throw HighscoreServiceError.invalidResponse }
            var data = Data()
            for try await byte in bytes { guard data.count < 16_384 else { bytes.task.cancel(); throw HighscoreServiceError.invalidResponse }; data.append(byte) }
            if (report == nil && response.statusCode == 200) || (report != nil && [200, 201].contains(response.statusCode)) {
                guard response.mimeType == "application/json" else { throw HighscoreServiceError.invalidResponse }
                let receipt = try HighscoreSnapshot.decoder().decode(ReportReceipt.self, from: data)
                try receipt.validate()
                guard receipt.reportId == id || report != nil && receipt.alreadyPending == true else { throw HighscoreServiceError.invalidResponse }
                return receipt
            }
            guard response.mimeType == "application/problem+json", let problem = try? JSONDecoder().decode(HighscoreProblem.self, from: data), problem.status == response.statusCode else { throw HighscoreServiceError.invalidResponse }
            throw HighscoreServiceError.rejected(problem)
        } catch HighscoreServiceError.rejected(let problem) { throw HighscoreServiceError.rejected(problem) }
        catch { throw report == nil ? HighscoreServiceError.unavailable : HighscoreServiceError.unconfirmed }
    }
}
