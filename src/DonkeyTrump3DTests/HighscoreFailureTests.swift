import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Highscore failures") @MainActor
struct HighscoreFailureTests {
    @Test(arguments: ["submission_unconfirmed", "submission_conflict", "rate_limited", "service_unavailable", "internal_error", "score-validation"])
    func TerminalSaveFailuresCannotBeResent(_ code: String) async {
        let status = code == "submission_conflict" ? 409 : code == "rate_limited" ? 429 : code == "score-validation" ? 400 : 503
        let service = ScriptedHighscoreService(read: { HighscoreFixtureService.prepared(count: 0) }, submit: { _ in
            throw HighscoreServiceError.rejected(.init(type: "about:blank", title: "Unavailable", status: status,
                code: code == "score-validation" ? "validation_failed" : code,
                errors: code == "score-validation" ? ["score": ["Invalid score"]] : nil))
        })
        let coordinator = HighscoreCoordinator(service: service)
        let run = CompletedRun(id: UUID(), score: 1200, levelReached: 2)
        coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: "Løkke")
        #expect(await eventually { if case .failed = coordinator.state { true } else { false } })
        if case .failed(let message, _) = coordinator.state {
            #expect(message.contains("couldn't confirm") == ["submission_unconfirmed", "internal_error"].contains(code))
        }
        coordinator.refresh()
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        coordinator.complete(run); coordinator.submit(name: "Again"); coordinator.cancel(); coordinator.complete(run)
        #expect(coordinator.state == .closed); #expect(await service.posts.count == 1)
    }
    @Test(arguments: ["internal_error", "unknown_problem", "submission_unconfirmed"])
    func rejectedReadsNeverImplyUnconsentedPublication(_ code: String) async {
        for fromTitle in [true, false] {
            let service = ScriptedHighscoreService(read: {
                throw HighscoreServiceError.rejected(.init(type: "about:blank", title: "Unavailable", status: 500, code: code, errors: nil))
            })
            let coordinator = HighscoreCoordinator(service: service)
            let run = CompletedRun(id: UUID(), score: 1200, levelReached: 1)
            if fromTitle { coordinator.openTitle() } else { coordinator.complete(run) }
            #expect(await eventually { if case .failed = coordinator.state { true } else { false } })
            guard case .failed(let message, _) = coordinator.state else { continue }
            #expect(message == Copy.highscoreUnavailable)
            #expect(!message.contains("couldn't confirm"))
            coordinator.submit(name: "No consent")
            if !fromTitle { coordinator.complete(run) }
            #expect(await service.posts.isEmpty)
            #expect(await service.reads == 1)
        }
    }
    @Test func FailedQualificationDoesNotInferRankOrPublishLater() async {
        let response = MutableHighscoreRead(); await response.set(.failure(.unavailable))
        let service = ScriptedHighscoreService(read: { try await response.read() })
        let coordinator = HighscoreCoordinator(service: service); let run = CompletedRun(id: UUID(), score: 1200, levelReached: 1)
        coordinator.complete(run)
        #expect(await eventually { if case .failed = coordinator.state { true } else { false } })
        await response.set(.success(HighscoreFixtureService.prepared(count: 0))); coordinator.refresh()
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        coordinator.complete(run); coordinator.submit(name: "No replay")
        #expect(await service.posts.isEmpty)
    }
    @Test(arguments: ["cancel", "background", "timeout", "new-run"])
    func LateSaveCannotInterruptNewState(_ action: String) async {
        let response = DelayedHighscoreResponse(); let clock = ManualHighscoreClock()
        let service = ScriptedHighscoreService(read: { HighscoreFixtureService.prepared(count: 0) }, submit: { _ in try await response.value() })
        let coordinator = HighscoreCoordinator(service: service, clock: clock); let run = CompletedRun(id: UUID(), score: 1200, levelReached: 1)
        coordinator.complete(run); #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: "Test"); #expect(await eventually { await response.isWaiting })
        switch action {
        case "timeout":
            #expect(await eventually { await clock.pendingCount > 0 }); await clock.expire()
            #expect(await eventually { if case .failed = coordinator.state { true } else { false } })
        case "background": coordinator.background()
        default: coordinator.invalidate()
        }
        let prior = coordinator.state
        let ranked = HighscoreSnapshot(entries: [.init(entryId: run.id, rank: 1, displayName: "Test", score: 1200)], revision: "committed", fetchedAtUtc: Date(), outcome: .ranked, entryId: run.id, rank: 1)
        await response.resolve(ranked); try? await Task.sleep(for: .milliseconds(20))
        #expect(coordinator.state == prior); coordinator.complete(run); coordinator.submit(name: "Again")
        #expect(await service.posts.count == 1)
    }
}
