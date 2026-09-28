import Foundation
import Observation

enum ReportState: Equatable {
    case closed, history
    case form(entryId: UUID, reportId: UUID)
    case waiting(UUID)
    case result(UUID, String)
}

@MainActor @Observable final class ReportCoordinator {
    private(set) var state: ReportState = .closed
    private(set) var receipts: [LocalReportReceipt] = []
    @ObservationIgnored private let service: any ReportService
    @ObservationIgnored private let store: ReportReceiptStore
    @ObservationIgnored private let clock: any HighscoreClock
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var deadline: Task<Void, Never>?
    private var generation: UInt64 = 0
    init(service: any ReportService, store: ReportReceiptStore = .shared, clock: any HighscoreClock = ContinuousHighscoreClock()) {
        self.service = service; self.store = store; self.clock = clock
    }
    deinit { task?.cancel(); deadline?.cancel() }
    var isPresented: Bool { state != .closed }
    func close() { stop(); state = .closed }
    func open(entryId: UUID) { stop(); state = .form(entryId: entryId, reportId: UUID()) }
    func history() {
        stop(); state = .history
        let expected = generation
        task = Task { [weak self, store] in
            let saved = (try? await store.load()) ?? []
            guard let self, self.generation == expected else { return }
            self.receipts = saved
        }
    }
    func send(reason: ReportReason) {
        guard case .form(let entryId, let reportId) = state else { return }
        begin(id: reportId, submission: .init(reportId: reportId, entryId: entryId, reason: reason))
    }
    func check(_ id: UUID) { begin(id: id, submission: nil) }
    private func begin(id: UUID, submission: ReportSubmission?) {
        stop(); state = .waiting(id)
        let expected = generation
        deadline = Task { [weak self, clock] in
            do { try await clock.sleepForDeadline() } catch { return }
            guard let self, self.generation == expected else { return }
            self.stop(); self.state = .result(id, "The response could not be confirmed. Check Status later or contact support. A missing receipt does not prove that no report was saved.")
        }
        task = Task { [weak self, service, store] in
            do {
                let receipt: ReportReceipt
                if let submission {
                    // Generic ID only: this never contains a queued payload or offending name.
                    try await store.save(.init(id: id, updatedAt: Date(), status: "unconfirmed"))
                    try Task.checkCancellation()
                    receipt = try await service.submit(submission)
                } else { receipt = try await service.status(id) }
                try receipt.validate()
                try await store.replace(id, with: .init(id: receipt.reportId, updatedAt: Date(), status: receipt.status))
                guard let self, self.generation == expected else { return }
                self.stop(); self.state = .result(receipt.reportId, receipt.message)
            } catch {
                guard let self, self.generation == expected else { return }
                var message = "The response could not be confirmed. Check Status later or contact support."
                if case HighscoreServiceError.rejected(let problem) = error {
                    if problem.status == 404 && submission == nil {
                        try? await store.remove(id)
                        message = "This receipt is unavailable or expired. A missing receipt does not prove that an earlier report was not saved. Contact support if you still need help."
                    } else if !["report_unconfirmed"].contains(problem.code) {
                        message = "The request was not accepted. You can keep playing or contact support."
                    }
                } else if case HighscoreServiceError.credentialUnavailable = error {
                    message = "Reporting is unavailable on this installation. You can keep playing or contact support."
                }
                guard self.generation == expected else { return }
                self.stop(); self.state = .result(id, message)
            }
        }
    }
    private func stop() { generation &+= 1; task?.cancel(); task = nil; deadline?.cancel(); deadline = nil }
}
