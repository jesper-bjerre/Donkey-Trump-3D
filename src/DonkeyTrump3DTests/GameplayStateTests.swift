import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Gameplay state boundaries")
struct GameplayStateTests {
    @Test func retryRetainsLevelButRestartReplacesIt() throws {
        let s = GameSession(seed: 1)
        _ = s.restart()
        let id = try #require(s.runID)
        let old = try #require(s.attempt)
        _ = s.resolve(candidates: [.init(runID: id, attemptSerial: old.attemptSerial,
            registeredAtNs: 0, reason: .collision)], clearances: [])
        _ = s.update(ns: 1_400_000_000, input: .init())
        _ = s.update(ns: 600_000_000, input: .init())
        #expect(s.attempt?.attemptSerial != old.attemptSerial)
        #expect(s.runID == id)
        #expect(s.levelProgress?.totalActiveNs == 0)
        _ = s.restart()
        #expect(s.runID != id)
        #expect(s.stats.score == 0)
        #expect(s.attempt?.remainingNs == 180_000_000_000)
    }

    @Test func checkedArithmeticAndCopiedPayloads() {
        #expect(ScoreRules.completion(level: Int.max) == nil)
        #expect(ActiveDuration.add(Int64.max, 1) == nil)
        let id = BarrelLifetimeID(runID: UUID(), attemptSerial: 1, spawnSerial: 1)
        let award = ScoreAward(lifetime: id, registeredAtNs: 60_000_000_000,
            source: .barrel, points: 10, position: .init(x: 1, y: 2))
        #expect(award.points == 10)
        #expect(award.registeredAtNs == 60_000_000_000)
    }
}
