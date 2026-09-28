import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Moderation client", .serialized)
struct ModerationTests {
    @Test func credentialIsStableAndCorruptionDoesNotRotateIt() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("credential")
        let store = InstallationCredentialStore(file: file)
        let first = try await store.authorization()
        #expect(first.count == 50)
        #expect(first.hasPrefix("Bearer "))
        let reopened = InstallationCredentialStore(file: file)
        #expect(try await reopened.authorization() == first)
        try Data("corrupt".utf8).write(to: file)
        let corrupt = InstallationCredentialStore(file: file)
        await #expect(throws: (any Error).self) { try await corrupt.authorization() }
        #expect(try Data(contentsOf: file) == Data("corrupt".utf8))
    }
    @Test func receiptsStoreOnlyBoundedGenericStatusAndNeverQueueAnUpload() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("receipts.json")
        let store = ReportReceiptStore(file: file)
        for _ in 0..<25 { try await store.save(.init(id: UUID(), updatedAt: Date(), status: "pending")) }
        let receipts = try await store.load()
        #expect(receipts.count == 20)
        let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [[String: Any]])
        #expect(json.allSatisfy { Set($0.keys) == Set(["id", "updatedAt", "status"]) })
        try await store.remove(receipts[0].id)
        #expect(try await store.load().count == 19)
    }
    @Test func onlyNameRejectionAllowsCurrentRunCorrection() {
        #expect(HighscoreProblem(type: "about:blank", title: "Name", status: 422, code: "name_rejected", errors: nil).editableNameError)
        #expect(!HighscoreProblem(type: "about:blank", title: "Blocked", status: 403, code: "publication_blocked", errors: nil).editableNameError)
        #expect(!HighscoreProblem(type: "about:blank", title: "Validation", status: 400, code: "validation_failed", errors: ["displayName": ["Name"]]).editableNameError)
    }
}

actor DelayedReportService: ReportService {
    var posts = 0
    var reads = 0
    private var continuation: CheckedContinuation<ReportReceipt, Error>?
    func submit(_ report: ReportSubmission) async throws -> ReportReceipt {
        posts += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }
    func status(_ id: UUID) async throws -> ReportReceipt {
        reads += 1
        throw HighscoreServiceError.rejected(.init(type: "about:blank", title: "Expired", status: 404, code: "report_not_found", errors: nil))
    }
    func complete(_ receipt: ReportReceipt) { continuation?.resume(returning: receipt); continuation = nil }
}

@Suite("Report cancellation", .serialized) @MainActor
struct ReportCoordinatorTests {
    @Test func deadlineRetainsOnlyReceiptAndLateResultCannotReopenUI() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = ReportReceiptStore(file: folder.appendingPathComponent("receipts"))
        let service = DelayedReportService(), clock = ManualHighscoreClock()
        let coordinator = ReportCoordinator(service: service, store: store, clock: clock)
        coordinator.open(entryId: UUID())
        guard case .form(_, let requested) = coordinator.state else { Issue.record("Missing form"); return }
        coordinator.send(reason: .other)
        #expect(await eventually { let posts = await service.posts; let count = await clock.pendingCount; return posts == 1 && count == 1 })
        await clock.expire()
        #expect(await eventually { if case .result = coordinator.state { true } else { false } })
        coordinator.close()
        let canonical = UUID()
        await service.complete(.init(reportId: canonical, status: "pending", createdAtUtc: Date(), acknowledgedAtUtc: nil, resolvedAtUtc: nil, disposition: nil, alreadyPending: true))
        #expect(await eventually { (try? await store.load().first?.id) == canonical })
        #expect(coordinator.state == .closed)
        #expect(await service.posts == 1)
        #expect(!(try await store.load()).contains { $0.id == requested })
        coordinator.check(canonical)
        #expect(await eventually { if case .result(_, let message) = coordinator.state { message.contains("does not prove") } else { false } })
        #expect(try await store.load().isEmpty)
        #expect(await service.posts == 1)
    }
}
