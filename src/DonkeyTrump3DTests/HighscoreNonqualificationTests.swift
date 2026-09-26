import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Highscore nonqualification") @MainActor
struct HighscoreNonqualificationTests {
    @Test(arguments: ["below-cutoff", "equal-cutoff"])
    func freshMissShowsBottomWithoutName(_ fixture: String) async {
        let service = HighscoreFixtureService(fixture); let run = HighscoreFixtureLaunch.run(for: fixture)
        let coordinator = HighscoreCoordinator(service: service); coordinator.complete(run)
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        guard case .browsing(let browse) = coordinator.state else { return }
        #expect(browse.anchor == .bottom); #expect(browse.finalScore == run.score)
        #expect(await service.requestCounts().posts == 0)
        coordinator.complete(run); #expect(await service.requestCounts().reads == 1)
    }
    @Test func cutoffCanRiseAfterQualification() async {
        let service = HighscoreFixtureService("cutoff-race"); let run = HighscoreFixtureLaunch.run(for: "cutoff-race")
        let coordinator = HighscoreCoordinator(service: service); coordinator.complete(run)
        #expect(await eventually { coordinator.state == .enteringName(run, error: nil) })
        coordinator.submit(name: "Løkke")
        #expect(await eventually { if case .browsing = coordinator.state { true } else { false } })
        guard case .browsing(let browse) = coordinator.state else { return }
        #expect(browse.anchor == .bottom); #expect(browse.message?.contains("list changed") == true)
        #expect(!browse.snapshot.qualifies(run.score)); #expect(browse.finalScore == 300)
    }
    @Test func displacementUsesIdentityRatherThanDuplicateName() {
        let snapshot = HighscoreFixtureService.prepared(count: 100)
        let old = HighscoreBrowse(snapshot: snapshot, anchor: .highlight(UUID()), finalScore: 100)
        let updated = old.refreshed(with: snapshot)
        #expect(updated.anchor == .bottom)
        #expect(updated.message?.contains("no longer") == true)
        #expect(updated.finalScore == 100); #expect(!updated.stale)
    }
}
