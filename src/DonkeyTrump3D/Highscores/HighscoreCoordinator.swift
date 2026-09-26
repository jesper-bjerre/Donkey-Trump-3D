import Foundation
import Observation

@MainActor @Observable final class HighscoreCoordinator {
    private(set) var state: HighscoreState = .closed
    private(set) var source: HighscoreSource?
    private(set) var outcomes: [UUID: HighscoreRunOutcome] = [:]
    @ObservationIgnored private let service: any HighscoreService
    @ObservationIgnored private let clock: any HighscoreClock
    @ObservationIgnored private var requestTask: Task<Void, Never>?
    @ObservationIgnored private var deadlineTask: Task<Void, Never>?
    private var generation: UInt64 = 0
    private var cache: HighscoreSnapshot?
    private var refreshContext: HighscoreBrowse?

    init(service: any HighscoreService, clock: any HighscoreClock = ContinuousHighscoreClock()) {
        self.service = service; self.clock = clock
    }
    deinit { requestTask?.cancel(); deadlineTask?.cancel() }

    func complete(_ run: CompletedRun) {
        guard outcomes[run.id] == nil else { return }
        if source == .completedRun(run), state.isPresented { return }
        invalidate()
        source = .completedRun(run)
        guard run.id != HighscoreRules.zeroID, HighscoreRules.validScore(run.score), (1...2_147_483_647).contains(run.levelReached) else {
            outcomes[run.id] = .failed
            state = .failed(message: "This result cannot be submitted. Your personal best is saved on this iPhone.", cached: nil)
            return
        }
        state = .loading(.completedRun(run))
        begin(submission: nil) { [weak self] snapshot in
            guard let self else { return }
            self.cache = snapshot
            if snapshot.qualifies(run.score) { self.state = .enteringName(run, error: nil) }
            else {
                self.outcomes[run.id] = .notQualified
                self.state = .browsing(.init(snapshot: snapshot, anchor: .bottom, finalScore: run.score))
            }
        }
    }

    func submit(name: String) {
        guard case .enteringName(let run, _) = state, outcomes[run.id] == nil else { return }
        guard let canonical = HighscoreRules.name(name) else {
            state = .enteringName(run, error: "Enter a single-line name containing 1–20 characters."); return
        }
        guard let submission = try? HighscoreSubmission(run: run, name: canonical) else {
            fail(unconfirmed: false); return
        }
        state = .submitting(run)
        begin(submission: submission) { [weak self] snapshot in
            guard let self else { return }
            self.cache = snapshot
            if snapshot.outcome == .ranked {
                self.outcomes[run.id] = .published
                self.state = .browsing(.init(snapshot: snapshot, anchor: .highlight(run.id), finalScore: run.score))
            } else {
                self.outcomes[run.id] = .notQualified
                self.state = .browsing(.init(snapshot: snapshot, anchor: .bottom, finalScore: run.score,
                    message: "The list changed while you entered your name. Try again to reach the top 100."))
            }
        }
    }

    func openTitle() {
        invalidate(); source = .title; state = .loading(.title)
        begin(submission: nil) { [weak self] snapshot in
            self?.cache = snapshot
            self?.state = .browsing(.init(snapshot: snapshot, anchor: .top))
        }
    }

    /// A refresh only reads the list; terminal runs never regain a submission opportunity.
    func refresh() {
        guard let source else { return }
        let previous: HighscoreBrowse?
        switch state {
        case .browsing(let browse): previous = browse
        case .failed(_, let cached): previous = cached
        default: return
        }
        refreshContext = previous
        state = .loading(source)
        begin(submission: nil) { [weak self] snapshot in
            guard let self else { return }
            self.cache = snapshot
            self.state = .browsing(previous?.refreshed(with: snapshot) ?? .init(snapshot: snapshot, anchor: .top))
            self.refreshContext = nil
        }
    }

    func cancel() { invalidate() }
    func invalidate() {
        if case .completedRun(let run) = source, outcomes[run.id] == nil { outcomes[run.id] = .cancelled }
        stopOperation(); source = nil; state = .closed; refreshContext = nil
    }

    private func begin(submission: HighscoreSubmission?, success: @escaping @MainActor (HighscoreSnapshot) -> Void) {
        stopOperation()
        let expectedGeneration = generation, expectedSource = source
        let service = service, clock = clock
        deadlineTask = Task { [weak self] in
            do { try await clock.sleepForDeadline() } catch { return }
            guard let self, self.generation == expectedGeneration, self.source == expectedSource else { return }
            self.fail(unconfirmed: submission != nil)
        }
        requestTask = Task { [weak self] in
            do {
                let snapshot: HighscoreSnapshot
                if let submission { snapshot = try await service.submit(submission) }
                else { snapshot = try await service.read() }
                try snapshot.validate(submission: submission != nil)
                if let submission, snapshot.outcome == .ranked, snapshot.entryId != submission.submissionId { throw HighscoreServiceError.unconfirmed }
                if let submission, snapshot.outcome == .notQualified,
                   snapshot.qualifies(submission.score) || snapshot.entries.contains(where: { $0.id == submission.submissionId }) { throw HighscoreServiceError.unconfirmed }
                guard let self, self.generation == expectedGeneration, self.source == expectedSource else { return }
                self.stopOperation(); success(snapshot)
            } catch {
                guard let self, self.generation == expectedGeneration, self.source == expectedSource else { return }
                if case HighscoreServiceError.rejected(let problem) = error, problem.editableNameError,
                   case .completedRun(let run) = self.source, submission != nil {
                    self.stopOperation()
                    self.state = .enteringName(run, error: problem.errors?["displayName"]?.first ?? "Please check your name.")
                } else {
                    let unconfirmed: Bool
                    if case HighscoreServiceError.rejected(let problem) = error {
                        unconfirmed = submission != nil && (problem.code == "submission_unconfirmed" || !["validation_failed", "malformed_request", "submission_conflict", "payload_too_large", "unsupported_media_type", "rate_limited", "service_unavailable", "storage_invalid", "contention_exhausted", "operation_timed_out"].contains(problem.code))
                    } else { unconfirmed = submission != nil }
                    self.fail(unconfirmed: unconfirmed)
                }
            }
        }
    }

    private func stopOperation() {
        generation &+= 1
        requestTask?.cancel(); requestTask = nil
        deadlineTask?.cancel(); deadlineTask = nil
    }
    private func fail(unconfirmed: Bool) {
        stopOperation()
        let score: Int?
        if case .completedRun(let run) = source { if outcomes[run.id] == nil { outcomes[run.id] = .failed }; score = run.score } else { score = nil }
        var stale = refreshContext ?? cache.map { HighscoreBrowse(snapshot: $0, anchor: .top, finalScore: score) }
        stale?.stale = true; refreshContext = nil
        state = .failed(message: unconfirmed ? Copy.highscoreUnconfirmed : Copy.highscoreUnavailable, cached: stale)
    }
}

extension HighscoreCoordinator {
    func background() { invalidate() }
}
