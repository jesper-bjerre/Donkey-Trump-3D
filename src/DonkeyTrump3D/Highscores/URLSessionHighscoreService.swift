import Foundation

/// A separate delegate has no reference back to the session. Never replay a POST through a redirect.
private final class HighscoreRedirectPolicy: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

final class URLSessionHighscoreService: HighscoreService, @unchecked Sendable {
    private let configuration: HighscoreConfiguration
    private let session: URLSession
    init(configuration: HighscoreConfiguration, sessionConfiguration: URLSessionConfiguration? = nil) {
        self.configuration = configuration
        let transport = sessionConfiguration ?? .ephemeral
        transport.waitsForConnectivity = false
        transport.timeoutIntervalForRequest = 8
        transport.timeoutIntervalForResource = 8
        transport.urlCache = nil; transport.httpCookieStorage = nil
        transport.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        session = URLSession(configuration: transport, delegate: HighscoreRedirectPolicy(), delegateQueue: nil)
    }
    deinit { session.invalidateAndCancel() }
    func read() async throws -> HighscoreSnapshot { try await execute(nil) }
    func submit(_ submission: HighscoreSubmission) async throws -> HighscoreSnapshot { try await execute(submission) }

    private func execute(_ submission: HighscoreSubmission?) async throws -> HighscoreSnapshot {
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = submission == nil ? "GET" : "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let submission {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(submission)
        }
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let response = response as? HTTPURLResponse, response.url == configuration.endpoint else { throw HighscoreServiceError.invalidResponse }
            var data = Data()
            for try await byte in bytes {
                guard data.count < 256 * 1024 else { bytes.task.cancel(); throw HighscoreServiceError.invalidResponse }
                data.append(byte)
            }
            if response.statusCode == 200 {
                guard response.mimeType == "application/json" else { throw HighscoreServiceError.invalidResponse }
                let result = try HighscoreSnapshot.decode(data, submission: submission != nil)
                if let submission, result.outcome == .ranked {
                    guard result.entryId == submission.submissionId,
                          let row = result.entries.first(where: { $0.id == submission.submissionId }),
                          row.score == submission.score, row.displayName == submission.displayName else { throw HighscoreServiceError.invalidResponse }
                }
                if let submission, result.outcome == .notQualified {
                    guard !result.qualifies(submission.score),
                          !result.entries.contains(where: { $0.id == submission.submissionId }) else { throw HighscoreServiceError.invalidResponse }
                }
                return result
            }
            guard response.mimeType == "application/problem+json",
                  let problem = try? JSONDecoder().decode(HighscoreProblem.self, from: data), problem.status == response.statusCode else {
                throw HighscoreServiceError.invalidResponse
            }
            throw HighscoreServiceError.rejected(problem)
        } catch HighscoreServiceError.rejected(let problem) { throw HighscoreServiceError.rejected(problem) }
        catch { throw submission == nil ? HighscoreServiceError.unavailable : HighscoreServiceError.unconfirmed }
    }
}
