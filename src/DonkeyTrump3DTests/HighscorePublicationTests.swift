import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Highscore publication") @MainActor
struct HighscorePublicationTests {
    @Test func zeroQualifiesOnlyAfterFreshReadAndCancellingDoesNotPost() async {
        let service = HighscoreFixtureService("empty")
        let coordinator = HighscoreCoordinator(service: service)
        let run = CompletedRun(id: UUID(), score: 0, levelReached: 1)
        coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.cancel(); #expect(coordinator.state == .closed)
        #expect(await service.requestCounts().posts == 0)
        coordinator.complete(run); #expect(coordinator.state == .closed)
    }
    @Test func publishesExactlyThisRunAndReturnedSnapshot() async throws {
        let service = HighscoreFixtureService("rank-50")
        let coordinator = HighscoreCoordinator(service: service)
        let run = HighscoreFixtureLaunch.run(for: "rank-50")
        coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: " Løkke "); coordinator.submit(name: "Second tap")
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        guard case .browsing(let browse) = coordinator.state else { return }
        #expect(browse.anchor == .highlight(run.id)); #expect(browse.snapshot.rank == 50)
        #expect(browse.snapshot.entries.first(where: { $0.id == run.id })?.displayName == "Løkke")
        #expect(await service.requestCounts().posts == 1)
        #expect(await service.requestCounts().reads == 1)
    }
    @Test func confirmedNameRejectionAllowsExplicitCorrection() async {
        let service = HighscoreFixtureService("validation-error")
        let coordinator = HighscoreCoordinator(service: service); let run = HighscoreFixtureLaunch.run(for: "validation-error")
        coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: "A")
        #expect(await eventually { if case .enteringName(_, let error) = coordinator.state { error != nil } else { false } })
        coordinator.submit(name: "B")
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        #expect(await service.requestCounts().posts == 2)
    }
    @Test func independentDeadlineDoesNotWaitForCancelledTransport() async {
        let delayed = DelayedHighscoreResponse(); let clock = ManualHighscoreClock()
        let service = ScriptedHighscoreService(read: { try await delayed.value() })
        let coordinator = HighscoreCoordinator(service: service, clock: clock)
        let run = CompletedRun(id: UUID(), score: 0, levelReached: 1)
        coordinator.complete(run)
        #expect(await eventually { let waiting = await delayed.isWaiting; let pending = await clock.pendingCount; return waiting && pending == 1 })
        await clock.expire()
        #expect(await eventually { if case .failed = coordinator.state { true } else { false } })
        await delayed.resolve(HighscoreFixtureService.prepared(count: 0))
        await Task.yield(); #expect({ if case .failed = coordinator.state { true } else { false } }())
    }
    @Test(arguments: [10, 1005]) func exactFivePointPublication(_ score: Int) async {
        let service = HighscoreFixtureService("empty")
        let c = HighscoreCoordinator(service: service)
        let run = CompletedRun(id: UUID(), score: score, levelReached: 1)
        c.complete(run)
        #expect(await eventually { c.state == .enteringName(run, error: nil) })
        c.submit(name: "Exact")
        #expect(await eventually { if case .browsing = c.state { true } else { false } })
        if case .browsing(let browse) = c.state {
            #expect(browse.snapshot.entries.first { $0.id == run.id }?.score == score)
        }
        #expect(await service.requestCounts().posts == 1)
        c.invalidate(); c.complete(run); c.submit(name: "Again")
        #expect(await service.requestCounts().posts == 1)
    }

}
