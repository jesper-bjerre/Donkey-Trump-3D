import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Completed run")
struct CompletedRunTests {
    @Test func identitiesChangeOnlyForNewRuns() throws {
        let session = GameSession(seed: 3)
        #expect(session.completedRun == nil)
        session.startNewGame(); let first = try #require(session.runID)
        _ = session.beginPlay(); session.pause(); session.resume()
        #expect(session.runID == first)
        _ = session.restart(); #expect(session.runID != first)
        #expect(session.completedRun == nil)
        session.showTitle(); #expect(session.runID == nil)
    }
    @Test func onlyFinalLifeFreezesScoreAndPreservesLocalBest() throws {
        var saved: Int?
        let session = GameSession(seed: 3, best: 99_900) { saved = $0 }
        session.startNewGame(); _ = session.beginPlay()
        let runID = session.runID
        for life in 1...3 {
            let sim = session.sim
            let barrel = sim.barrels.spawn(at: .init(x: sim.player.x, y: sim.player.feet - 60)); barrel.vx = 0
            for _ in 0..<240 {
                _ = session.update(dt: 1.0 / 120, input: InputState())
                if session.phase != .play { break }
            }
            if life < 3 {
                #expect(session.completedRun == nil)
                for _ in 0..<360 { _ = session.update(dt: 1.0 / 120, input: InputState()) }
            }
        }
        #expect(session.phase == .gameOver)
        let result = try #require(session.completedRun)
        #expect(result.id == runID); #expect(result.score == session.stats.score)
        #expect(result.score != session.best); #expect(result.levelReached == 1); #expect(saved == 99_900)
        for _ in 0..<50 { _ = session.update(dt: 0.1, input: InputState()) }
        #expect(session.completedRun == result)
        _ = session.restart(); #expect(session.completedRun == nil); #expect(session.runID != runID)
    }
    @Test func rescueAndAbandonedRunDoNotComplete() {
        let session = GameSession(seed: 12); session.startNewGame(); _ = session.beginPlay()
        var bot = Autopilot()
        for _ in 0..<(120 * 120) {
            _ = session.update(dt: 1.0 / 120, input: bot.input(for: session.sim, dt: 1.0 / 120))
            if session.phase == .levelComplete { break }
        }
        #expect(session.phase == .levelComplete); #expect(session.completedRun == nil)
        session.showTitle(); #expect(session.completedRun == nil)
    }
}
