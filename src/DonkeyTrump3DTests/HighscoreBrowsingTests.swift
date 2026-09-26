import Foundation
import Testing
@testable import DonkeyTrump3D

actor MutableHighscoreRead {
    var result: Result<HighscoreSnapshot, HighscoreServiceError> = .success(HighscoreFixtureService.prepared(count: 100))
    func set(_ value: Result<HighscoreSnapshot, HighscoreServiceError>) { result = value }
    func read() throws -> HighscoreSnapshot { try result.get() }
}

@Suite("Highscore browsing") @MainActor
struct HighscoreBrowsingTests {
    @Test func titleRefreshIsReadOnlyAndFailureShowsStaleCache() async {
        let response = MutableHighscoreRead()
        let service = ScriptedHighscoreService(read: { try await response.read() })
        let coordinator = HighscoreCoordinator(service: service)
        coordinator.openTitle()
        #expect(await eventually { if case .browsing(let b) = coordinator.state { b.anchor == .top && !b.stale } else { false } })
        await response.set(.failure(.unavailable)); coordinator.refresh()
        #expect(await eventually { if case .failed(_, let b) = coordinator.state { b?.stale == true } else { false } })
        await response.set(.success(HighscoreFixtureService.prepared(count: 0))); coordinator.refresh()
        #expect(await eventually { if case .browsing(let b) = coordinator.state { b.snapshot.entries.isEmpty && !b.stale } else { false } })
        #expect(await service.posts.isEmpty)
    }
    @Test func deadlineAndInvalidationDiscardUncooperativeOldResponses() async {
        for expire in [false, true] {
            let response = DelayedHighscoreResponse(); let clock = ManualHighscoreClock()
            let coordinator = HighscoreCoordinator(service: ScriptedHighscoreService(read: { try await response.value() }), clock: clock)
            coordinator.openTitle()
            #expect(await eventually { await response.isWaiting })
            #expect(await eventually { await clock.pendingCount == 1 })
            if expire { await clock.expire() } else { coordinator.invalidate() }
            #expect(await eventually { if expire { if case .failed = coordinator.state { return true }; return false }; return coordinator.state == .closed })
            let prior = coordinator.state
            await response.resolve(HighscoreFixtureService.prepared(count: 100))
            try? await Task.sleep(for: .milliseconds(20))
            #expect(coordinator.state == prior)
        }
    }
    @Test func refreshedDisplacementNeverRequalifiesCompletedRun() async {
        let run = CompletedRun(id: UUID(), score: 20_200, levelReached: 1)
        let initial = HighscoreFixtureService("rank-1")
        let reads = MutableHighscoreRead(); await reads.set(.success(.init(entries: [], revision: "empty", fetchedAtUtc: Date())))
        let service = ScriptedHighscoreService(read: { try await reads.read() }, submit: { try await initial.submit($0) })
        let coordinator = HighscoreCoordinator(service: service); coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: "Duplicate")
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        await reads.set(.success(HighscoreFixtureService.prepared(count: 100)))
        coordinator.refresh()
        #expect(await eventually { if case .browsing(let b) = coordinator.state { b.anchor == .bottom && b.message?.contains("no longer") == true } else { false } })
        coordinator.complete(run); coordinator.submit(name: "Again")
        #expect(await service.posts.count == 1)
    }
}
