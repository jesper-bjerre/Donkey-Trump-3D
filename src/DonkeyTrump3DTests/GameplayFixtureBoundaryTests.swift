import Testing
@testable import DonkeyTrump3D

@Suite("Gameplay fixture boundary")
struct GameplayFixtureBoundaryTests {
    @Test func everyPresenceFailsClosedBeforeParsing() {
        #expect(!GameplayFixtureLaunch.isPresent([]))
        #expect(GameplayFixtureLaunch.allowsPublication([]))
        for args in [["-gameplayFixture"], ["-gameplayFixture", "unknown"],
                     ["-gameplayFixture=upper-1"],
                     ["-gameplayFixture", "upper-1", "-gameplaySeed", "bad", "-highscoreIntegration"],
                     ["-gameplayFixture", "upper-1", "-gameplaySeed", "1", "-highscoreCompletedRun"]] {
            #expect(GameplayFixtureLaunch.isPresent(args))
            #expect(!GameplayFixtureLaunch.allowsPublication(args))
            #expect(!GameplayFixtureLaunch.usesPersistentBest(args))
        }
    }
    @Test func exactCasesRequireSeedAndKeepRealRules() {
        for layout in 1...3 {
            for prefix in ["upper", "retry-max", "limit-layout"] {
                let args = ["-gameplayFixture", "\(prefix)-\(layout)", "-gameplaySeed", "91"]
                let fixture = GameplayFixtureLaunch.parse(args)
                #expect(fixture != nil)
                let s = GameSession(seed: 91)
                if let fixture { #expect(s.install(fixture)) }
                #expect(s.attempt?.remainingNs == ActiveDuration.attempt)
                #expect(s.stats.score == 0)
                #expect(s.sim.player.isGrounded)
                #expect(!s.sim.player.bounds.overlaps(s.sim.rescueZone))
                #expect(s.sim.barrels.active.isEmpty)
            }
        }
        #expect(GameplayFixtureLaunch.parse(["-gameplayFixture", "upper-1"]) == nil)
    }
}
