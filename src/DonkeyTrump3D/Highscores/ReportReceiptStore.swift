import Foundation

struct LocalReportReceipt: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let updatedAt: Date
    let status: String
}

actor ReportReceiptStore {
    static let shared = ReportReceiptStore()
    private let file: URL
    init(file: URL? = nil) {
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Moderation/report-receipts.json")
    }
    func load() throws -> [LocalReportReceipt] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        let bytes = try Data(contentsOf: file)
        guard bytes.count <= 16_384 else { throw HighscoreServiceError.invalidResponse }
        let receipts = try JSONDecoder().decode([LocalReportReceipt].self, from: bytes)
        guard receipts.count <= 20, Set(receipts.map(\.id)).count == receipts.count,
              receipts.allSatisfy({ $0.id != HighscoreRules.zeroID && ["pending", "acknowledged", "resolved", "unconfirmed"].contains($0.status) }) else { throw HighscoreServiceError.invalidResponse }
        return receipts
    }
    func save(_ receipt: LocalReportReceipt) throws {
        var current = try load().filter { $0.id != receipt.id }
        current.insert(receipt, at: 0)
        try write(Array(current.prefix(20)))
    }
    func replace(_ oldID: UUID, with receipt: LocalReportReceipt) throws {
        var current = try load().filter { $0.id != oldID && $0.id != receipt.id }
        current.insert(receipt, at: 0)
        try write(Array(current.prefix(20)))
    }
    func remove(_ id: UUID) throws { try write(load().filter { $0.id != id }) }
    private func write(_ receipts: [LocalReportReceipt]) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(receipts).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        var url = file; var values = URLResourceValues(); values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}
