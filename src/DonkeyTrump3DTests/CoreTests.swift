import Testing
@testable import DonkeyTrump3D

@Suite("Levels")
struct LevelTests {
    @Test func loadsThreeAuthoredLayouts() {
        let layouts = LevelLibrary.layouts
        #expect(layouts.count == 3)
        #expect(layouts.map(\.name) == ["Girder Warm-Up", "Press Room Scramble", "Summit Showdown"])
        for level in layouts {
            #expect(level.girders.count >= 5)
            #expect(!level.ladders.isEmpty)
        }
    }

    @Test func everyFloorIsConnectedByALadder() {
        for level in LevelLibrary.layouts {
            let links = IntroTimeline.ladderLinks(level)
            for floor in 0..<(level.girders.count - 1) {
                #expect(links.contains { $0.bottom == floor && $0.top == floor + 1 }, "\(level.id) floor \(floor)")
            }
        }
    }

    @Test func jumpCannotReachTheNextFloor() {
        let apex = PlayerSettings().jumpApex
        for level in LevelLibrary.layouts {
            let segments = level.girders.map(Segment.init)
            for ladder in level.ladders {
                // Floor gap at every ladder is the ladder's height.
                #expect(ladder.height > apex, "\(level.id) \(ladder.id)")
            }
            #expect(segments.count > 1)
        }
    }

    @Test func endlessRampIsMonotonicAndBounded() {
        var previous = DifficultyRamp.level(at: 2).barrels
        for index in 3..<40 {
            let b = DifficultyRamp.level(at: index).barrels
            #expect(b.speedMax >= previous.speedMax)
            #expect(b.spawnIntervalMs <= previous.spawnIntervalMs)
            #expect(b.speedMax <= DifficultyRamp.speedMaxLimit)
            #expect(b.spawnIntervalMs >= DifficultyRamp.spawnIntervalLimitMs)
            #expect((b.maxActive ?? 0) <= DifficultyRamp.maxActiveCap)
            previous = b
        }
        #expect(DifficultyRamp.level(at: 4).layoutIndex == 1)
        #expect(DifficultyRamp.level(at: 4).rescue.isFinalLevel == false)
    }
}

@Suite("Slopes")
struct SlopeTests {
    let segment = Segment(x1: 800, y1: 568, x2: 0, y2: 580)

    @Test func storesLeftToRight() {
        #expect(segment.x1 == 0)
        #expect(segment.y1 == 580)
        #expect(segment.downhill == -1)
    }

    @Test func snapsFallingBodiesAndIgnoresRisingOnes() {
        let falling = Slope.resolve(x: 400, bottom: 578, velocityY: 50, segments: [segment])
        #expect(falling.grounded)
        #expect(abs(falling.bottom - 574) < 0.001)
        let rising = Slope.resolve(x: 400, bottom: 578, velocityY: -50, segments: [segment])
        #expect(!rising.grounded)
    }

    @Test func tiltingKeepsTheMidpoint() {
        let flat = segment.tilted(0)
        #expect(flat.y1 == flat.y2)
        #expect(flat.midY == segment.midY)
        #expect(segment.tilted(1) == segment)
    }
}

@Suite("Player")
struct PlayerTests {
    func settle(_ sim: GameSimulation, frames: Int = 60, input: InputState = InputState()) {
        for _ in 0..<frames { _ = sim.step(dt: 1.0 / 120, input: input) }
    }

    func quietLevel() -> Level {
        var level = LevelLibrary.layouts[0]
        level.barrels.firstSpawnDelayMs = 1_000_000
        return level
    }

    @Test func standsOnTheGroundFloorAndWalks() {
        let sim = GameSimulation(level: quietLevel(), seed: 1)
        settle(sim)
        #expect(sim.player.isGrounded)
        let x = sim.player.x
        var right = InputState()
        right.right = true
        settle(sim, frames: 120, input: right)
        #expect(abs(sim.player.x - x - 120) < 3)
        #expect(sim.player.isGrounded)
    }

    @Test func noDoubleJump() {
        let sim = GameSimulation(level: quietLevel(), seed: 1)
        settle(sim)
        var jump = InputState()
        jump.jumpPressed = true
        jump.jumpHeld = true
        let events = sim.step(dt: 1.0 / 120, input: jump)
        #expect(events.contains { if case .jump = $0 { return true }; return false })
        settle(sim, frames: 10, input: InputState(jumpHeld: true))
        let second = sim.step(dt: 1.0 / 120, input: jump)
        #expect(!second.contains { if case .jump = $0 { return true }; return false })
    }

    @Test func climbsALadderToTheNextFloor() {
        let level = quietLevel()
        let sim = GameSimulation(level: level, seed: 1)
        settle(sim)
        let ladder = level.ladders[0]
        var bot = Autopilot()
        var climbed = false
        for _ in 0..<(120 * 20) {
            let input = bot.input(for: sim, dt: 1.0 / 120)
            _ = sim.step(dt: 1.0 / 120, input: input)
            if sim.player.feet <= ladder.y + 0.5 && sim.player.isGrounded { climbed = true; break }
        }
        #expect(climbed)
    }
}

@Suite("Flow")
struct FlowTests {
    @Test func barrelHitCostsALifeAndRetriesTheLevel() {
        let session = GameSession(seed: 3)
        session.startNewGame()
        _ = session.beginPlay()
        let sim = session.sim
        // Drop a barrel right onto the player.
        let barrel = sim.barrels.spawn(at: LevelPoint(x: sim.player.x, y: sim.player.feet - 60))
        barrel.vx = 0
        var sawHit = false
        for _ in 0..<240 {
            let events = session.update(dt: 1.0 / 120, input: InputState())
            if events.contains(where: { if case .lifeLost = $0 { return true }; return false }) { sawHit = true; break }
        }
        #expect(sawHit)
        #expect(session.stats.lives == ScoreRules.startingLives - 1)
        for _ in 0..<(120 * 3) { _ = session.update(dt: 1.0 / 120, input: InputState()) }
        #expect(session.phase == .play)
    }

    @Test func autopilotClearsLevelOne() {
        let session = GameSession(seed: 12)
        session.startNewGame()
        _ = session.beginPlay()
        var bot = Autopilot()
        var completed = false
        for _ in 0..<(120 * 120) {
            let input = bot.input(for: session.sim, dt: 1.0 / 120)
            let events = session.update(dt: 1.0 / 120, input: input)
            if events.contains(where: { if case .levelComplete = $0 { return true }; return false }) { completed = true; break }
            if session.phase == .gameOver { break }
        }
        #expect(completed)
        #expect(session.stats.score >= ScoreRules.levelCompletePoints)
    }

    @Test func introTimelineIsOrdered() {
        let intro = IntroTimeline(level: LevelLibrary.layouts[0])
        #expect(intro.pathEnd > 0)
        #expect(intro.phase(at: 0) == .path)
        #expect(intro.phase(at: intro.pathEnd + 0.1) == .sign)
        #expect(intro.phase(at: intro.end + 1) == .done)
        #expect(intro.tilts(at: 0).allSatisfy { $0 == 0 })
        #expect(intro.tilts(at: intro.tiltEnd).allSatisfy { $0 == 1 })
        let top = intro.path.first { $0.action == .drop }
        #expect(top != nil)
    }
}
