import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Score, attempt time and difficulty")
struct ScoreTimerDifficultyTests {
    func candidates(_ s: GameSession, count: Int, at time: Int64, starting: Int = 1) throws -> [ClearanceCandidate] {
        let run = try #require(s.runID), attempt = try #require(s.attempt)
        return (starting..<(starting + count)).map {
            .init(lifetime: .init(runID: run, attemptSerial: attempt.attemptSerial, spawnSerial: UInt64($0)),
                  registeredAtNs: time, position: .init(x: 20, y: 30))
        }
    }
    func terminal(_ s: GameSession, at time: Int64, reason: TerminalReason) throws -> TerminalCandidate {
        .init(runID: try #require(s.runID), attemptSerial: try #require(s.attempt).attemptSerial,
              registeredAtNs: time, reason: reason)
    }
    @Test func referenceJourneys() throws {
        let s = GameSession(seed: 1); _ = s.restart()
        _ = s.resolve(candidates: [try terminal(s, at: 60_000_000_000, reason: .rescue)],
                      clearances: try candidates(s, count: 10, at: 60_000_000_000), through: 60_000_000_000)
        #expect(s.stats.score == 1700)
        _ = s.update(ns: 3_200_000_000, input: .init())
        #expect(s.level.order == 2)
        _ = s.resolve(candidates: [try terminal(s, at: 120_000_000_000, reason: .rescue)],
                      clearances: try candidates(s, count: 5, at: 120_000_000_000), through: 120_000_000_000)
        #expect(s.stats.score == 4400)
        #expect(s.levelProgress?.completionReward?.totalAfterCompletion == 4400)
    }
    @Test func capAndDistinctLifetimesSurviveDeath() throws {
        let s = GameSession(seed: 1); _ = s.restart()
        let first = try candidates(s, count: 12, at: 0)
        _ = s.resolve(candidates: [], clearances: first + first)
        #expect(s.stats.score == 120)
        _ = s.resolve(candidates: [try terminal(s, at: 0, reason: .collision)], clearances: [])
        _ = s.update(ns: 1_400_000_000, input: .init()); _ = s.update(ns: 600_000_000, input: .init())
        let next = try candidates(s, count: 10, at: 0)
        let events = s.resolve(candidates: [], clearances: next + first)
        #expect(s.stats.score == 200)
        #expect(s.levelProgress?.rewardedLifetimes.count == 20)
        #expect(events.filter { if case .scoreAward = $0 { return true }; return false }.count == 8)
        #expect(s.resolve(candidates: [], clearances: next).isEmpty)
    }
    @Test func emptyJumpMultiBarrelAndCompletionOnce() throws {
        let s = GameSession(seed: 1); _ = s.restart()
        #expect(s.resolve(candidates: [], clearances: []).isEmpty)
        _ = s.resolve(candidates: [], clearances: try candidates(s, count: 19, at: 0))
        _ = s.resolve(candidates: [], clearances: try candidates(s, count: 4, at: 0, starting: 20))
        #expect(s.stats.score == 200)
        let end = try terminal(s, at: 60_200_000_000, reason: .rescue)
        _ = s.resolve(candidates: [end, end], clearances: [], through: end.registeredAtNs)
        #expect(s.levelProgress?.completionReward?.bonusSeconds == 119)
        #expect(s.stats.score == 1795)
        #expect(s.resolve(candidates: [end], clearances: []).isEmpty)
    }
    @Test func wholeBonusBoundaries() {
        #expect(ScoreRules.bonusSeconds(totalActiveNs: 59_999_999_999) == 120)
        #expect(ScoreRules.bonusSeconds(totalActiveNs: 60_000_000_000) == 120)
        #expect(ScoreRules.bonusSeconds(totalActiveNs: 60_000_000_001) == 119)
        #expect(ScoreRules.bonusSeconds(totalActiveNs: 180_000_000_000) == 0)
        #expect(ActiveDuration.displaySeconds(1) == 1)
    }
}

extension ScoreTimerDifficultyTests {
    @Test func retainedTimeAndExactTimeout() throws {
        let s = GameSession(seed: 1); _ = s.restart()
        _ = s.resolve(candidates: [], clearances: [], through: 60_000_000_000)
        _ = s.resolve(candidates: [try terminal(s, at: 60_000_000_000, reason: .collision)], clearances: [])
        _ = s.update(ns: 1_400_000_000, input: .init()); _ = s.update(ns: 600_000_000, input: .init())
        _ = s.resolve(candidates: [], clearances: [], through: 120_000_000_000)
        #expect(s.attempt?.remainingNs == 120_000_000_000)
        #expect(s.levelProgress?.totalActiveNs == 120_000_000_000)
        _ = s.resolve(candidates: [], clearances: [], through: 240_000_000_000)
        #expect(s.stats.lives == 1)
        #expect(s.lastLossReason == .timeout)
        #expect(s.stats.score == 0)
    }
    @Test func timeoutFinalLifeAndStaleEventsFreezeResult() throws {
        let s = GameSession(seed: 1); _ = s.restart()
        var old: TerminalCandidate?
        for life in 0..<3 {
            let stop = Int64(life + 1) * ActiveDuration.attempt
            old = try terminal(s, at: stop, reason: .rescue)
            _ = s.resolve(candidates: [old!], clearances: [], through: stop)
            #expect(s.lastLossReason == .timeout)
            if life < 2 {
                _ = s.update(ns: 1_400_000_000, input: .init()); _ = s.update(ns: 600_000_000, input: .init())
                #expect(s.attempt?.remainingNs == ActiveDuration.attempt)
                #expect(s.levelProgress?.pressure == 1)
            }
        }
        let result = try #require(s.completedRun)
        _ = s.resolve(candidates: [old!], clearances: [])
        _ = s.update(ns: ActiveDuration.attempt, input: .init())
        #expect(s.completedRun == result)
        #expect(s.stats.lives == 0)
        #expect(s.phase == .gameOver)
    }
    @Test func terminalOrderAndLossBoundaryNeverAwardClearance() throws {
        for reverse in [false, true] {
            let s = GameSession(seed: 1); _ = s.restart()
            let time: Int64 = 179_999_999_999
            let collision = try terminal(s, at: time, reason: .collision)
            let rescue = try terminal(s, at: time, reason: .rescue)
            _ = s.resolve(candidates: reverse ? [rescue, collision] : [collision, rescue],
                          clearances: try candidates(s, count: 1, at: time), through: time)
            #expect(s.stats.lives == 2)
            #expect(s.stats.score == 0)
            #expect(s.lastLossReason == .collision)
        }
        let s = GameSession(seed: 1); _ = s.restart()
        _ = s.resolve(candidates: [try terminal(s, at: ActiveDuration.attempt, reason: .timeout),
                                  try terminal(s, at: ActiveDuration.attempt - 1, reason: .rescue)],
                      clearances: [], through: ActiveDuration.attempt)
        #expect(s.phase == .levelComplete)
        #expect(s.levelProgress?.totalActiveNs == ActiveDuration.attempt - 1)
    }
}

extension ScoreTimerDifficultyTests {
    @Test func pressureCheckpointsAndFloors() {
        let floors = [2.1, 2.0, 1.9, 1.9, 1.8, 1.8]
        for i in 0..<6 {
            var p = LevelProgress(level: DifficultyRamp.level(at: i))
            #expect(abs(p.minimumReleaseInterval - floors[i]) < 0.0001)
            for t in [0, 60, 120, 180, 240] {
                p.totalActiveNs = Int64(t) * ActiveDuration.second
                let pressure = min(1, Double(t) / 180)
                #expect(abs(p.speedMultiplier - (1 + 0.25 * pressure)) < 0.0001)
                let desired = p.baseBarrelConfiguration.spawnIntervalMs / 1000 * (1 - 0.60 * pressure)
                #expect(abs(p.desiredInterval - desired) < 0.0001)
                #expect(p.actualInterval >= p.minimumReleaseInterval)
                let unchanged = p.speedMultiplier
                #expect(p.speedMultiplier == unchanged)
            }
        }
        for i in 999...1001 {
            var p = LevelProgress(level: DifficultyRamp.level(at: i)); p.totalActiveNs = ActiveDuration.attempt
            #expect(p.minimumReleaseInterval == 1.4)
            #expect(p.baseBarrelConfiguration.speedMin == 240)
            #expect(p.baseBarrelConfiguration.speedMax == 280)
            #expect(p.baseBarrelConfiguration.maxActive == 12)
        }
    }
    @Test func pooledReleaseCopiesIdentityAndBallisticAimSurvivesFalling() {
        let level = DifficultyRamp.level(at: 2)
        let barrels = BarrelSystem(config: level.barrels, seed: 1)
        let b = barrels.spawn(at: .init(x: 600, y: 50), target: nil)
        let original = BarrelSnapshot(b)
        barrels.reset()
        let replacement = barrels.spawn(at: .init(x: 600, y: 50))
        #expect(replacement.id == original.id)
        #expect(replacement.lifetime != original.lifetime)
        #expect(original.x == 600)
        replacement.directFlight = true; replacement.mode = .falling
        replacement.vx = -123; replacement.targetFeet = 500
        barrels.applyPressure(speedMultiplier: 1.25, interval: 1.9)
        _ = barrels.update(dt: 1.0 / 120, spawnPoint: .init(x: 600, y: 50), target: nil,
                           segments: [], ladders: [], world: level.dimensions)
        #expect(replacement.vx == -123)
    }
    @Test func realEmitterPreservesFirstReleaseDelay() {
        let level = DifficultyRamp.level(at: 0)
        let b = BarrelSystem(config: level.barrels, seed: 7)
        for _ in 0..<179 {
            _ = b.update(dt: 1.0 / 120, spawnPoint: .init(x: 600, y: 50), target: nil,
                         segments: [], ladders: [], world: level.dimensions)
        }
        #expect(b.active.isEmpty)
        for _ in 0..<2 {
            _ = b.update(dt: 1.0 / 120, spawnPoint: .init(x: 600, y: 50), target: nil,
                         segments: [], ladders: [], world: level.dimensions)
        }
        #expect(b.active.count == 1)
    }
    @Test func firstDelayAndCappedOpportunitiesDoNotAccumulate() {
        var config = DifficultyRamp.level(at: 0).barrels
        config.maxActive = 0
        let b = BarrelSystem(config: config, seed: 1)
        let world = DifficultyRamp.level(at: 0).dimensions
        for _ in 0..<1200 {
            _ = b.update(dt: 1.0 / 120, spawnPoint: .init(x: 600, y: 50), target: nil,
                         segments: [], ladders: [], world: world)
        }
        #expect(b.active.isEmpty)
        #expect(b.nextSpawnAt > b.elapsed)
        #expect(b.timeToNextSpawn == nil)
    }
}
