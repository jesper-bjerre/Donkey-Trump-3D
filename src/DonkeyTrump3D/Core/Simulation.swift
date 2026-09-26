import Foundation

enum SimEvent {
    case jump
    case ladderExit
    case barrelThrown(Barrel)
    case barrelLanded(Barrel)
    case barrelJumped(Barrel)
    case hit(Barrel)
    case rescued
    // Flow events emitted by GameSession.
    case levelStarted(Int)
    case lifeLost(livesLeft: Int)
    case retry
    case levelComplete
    case gameOver
}

/// One level of play: the player, the barrels, hits, jump points and the rescue.
/// Framework-free and deterministic for a given seed.
final class GameSimulation {
    static let hitCooldown = 1.5
    static let hitboxInset = 3.0
    static let jumpDetectHeight = 56.0

    private(set) var level: Level
    private(set) var segments: [Segment]
    let player = Player()
    private(set) var barrels: BarrelSystem
    private(set) var time = 0.0
    private(set) var rescued = false
    private var invulnerableUntil = -Double.infinity
    private let seed: UInt64
    /// Every attempt gets fresh barrel randomness, so a retry is not a replay.
    private var attempt: UInt64 = 0

    init(level: Level, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.level = level
        self.seed = seed
        segments = level.girders.map(Segment.init)
        barrels = BarrelSystem(config: level.barrels, seed: seed)
        load(level)
    }

    func load(_ level: Level) {
        self.level = level
        segments = level.girders.map(Segment.init)
        attempt &+= 1
        barrels = BarrelSystem(config: level.barrels, seed: seed &+ UInt64(level.order) &* 31 &+ attempt &* 7919)
        player.reset(spawn: level.playerSpawn)
        time = 0
        rescued = false
        invulnerableUntil = -.infinity
    }

    /// The boss always stands in the rightmost quarter of the level.
    var bossPosition: LevelPoint {
        LevelPoint(x: min(max(level.boss.x, level.dimensions.width * 0.75), level.dimensions.width), y: level.boss.y)
    }

    var barrelSpawnPoint: LevelPoint {
        LevelPoint(x: bossPosition.x + level.boss.spawnAnchorOffset.x, y: bossPosition.y + level.boss.spawnAnchorOffset.y)
    }

    var rescueZone: Bounds {
        let r = level.rescue
        return Bounds(left: r.x, right: r.x + r.width, top: r.y, bottom: r.y + r.height)
    }

    func step(dt: Double, input: InputState) -> [SimEvent] {
        var events: [SimEvent] = []
        time += dt

        if player.updateLadder(input, ladders: level.ladders) { events.append(.ladderExit) }
        if player.updateMovement(input, now: time) { events.append(.jump) }
        player.integrate(dt: dt, world: level.dimensions)
        player.applySlope(segments: segments, now: time)

        let barrelEvents = barrels.update(
            dt: dt,
            spawnPoint: barrelSpawnPoint,
            target: (player.x, player.feet),
            segments: segments,
            ladders: level.ladders,
            world: level.dimensions
        )
        for event in barrelEvents {
            switch event {
            case .spawned(let b): events.append(.barrelThrown(b))
            case .landed(let b): events.append(.barrelLanded(b))
            }
        }

        let pb = player.bounds
        if player.isAirborne {
            for barrel in barrels.active where !barrel.jumpAwarded {
                let b = barrel.bounds
                let underFeet = b.top >= pb.bottom - 2 && b.top - pb.bottom <= GameSimulation.jumpDetectHeight
                if underFeet && pb.centerX >= b.left && pb.centerX <= b.right {
                    barrel.jumpAwarded = true
                    events.append(.barrelJumped(barrel))
                }
            }
        }

        if time >= invulnerableUntil {
            let hitbox = pb.inset(GameSimulation.hitboxInset)
            if let barrel = barrels.active.first(where: { hitbox.overlaps($0.bounds.inset(GameSimulation.hitboxInset)) }) {
                invulnerableUntil = time + GameSimulation.hitCooldown
                player.setHit()
                events.append(.hit(barrel))
                return events
            }
        }

        if !rescued && pb.overlaps(rescueZone) {
            rescued = true
            events.append(.rescued)
        }
        return events
    }
}

/// Arcade flow for a whole run: phases, score, lives and endless level progression.
final class GameSession {
    private(set) var runID: UUID?
    private(set) var completedRun: CompletedRun?
    private(set) var phase: GamePhase = .title
    private(set) var stats = ScoreLives()
    private(set) var phaseTime = 0.0
    private(set) var best: Int
    let sim: GameSimulation
    private let saveBest: (Int) -> Void

    init(seed: UInt64 = UInt64.random(in: 1...UInt64.max), best: Int = 0, saveBest: @escaping (Int) -> Void = { _ in }) {
        sim = GameSimulation(level: DifficultyRamp.level(at: 0), seed: seed)
        self.best = best
        self.saveBest = saveBest
    }

    var level: Level { sim.level }

    private func enter(_ next: GamePhase) {
        phase = next
        phaseTime = 0
    }

    func showTitle() {
        runID = nil
        completedRun = nil
        sim.load(DifficultyRamp.level(at: 0))
        enter(.title)
    }

    /// A new game opens with the executive-order cutscene on level 1.
    func startNewGame() {
        runID = UUID()
        completedRun = nil
        stats = ScoreLives()
        sim.load(DifficultyRamp.level(at: 0))
        enter(.intro)
    }

    func beginPlay() -> [SimEvent] {
        guard phase == .intro || phase == .title else { return [] }
        if runID == nil { runID = UUID(); completedRun = nil }
        sim.load(DifficultyRamp.level(at: stats.levelIndex))
        enter(.play)
        return [.levelStarted(stats.levelIndex)]
    }

    func pause() {
        if phase == .play { enter(.paused) }
    }

    func resume() {
        if phase == .paused { phase = .play }
    }

    func restart() -> [SimEvent] {
        runID = UUID()
        completedRun = nil
        stats = ScoreLives()
        sim.load(DifficultyRamp.level(at: 0))
        enter(.play)
        return [.levelStarted(0)]
    }

    #if DEBUG
    func completeForHighscoreFixture(_ run: CompletedRun) {
        runID = run.id; completedRun = run
        stats.score = run.score; stats.levelIndex = run.levelReached - 1; stats.lives = 0
        best = max(best, run.score); saveBest(best)
        sim.load(DifficultyRamp.level(at: stats.levelIndex)); enter(.gameOver)
    }
    #endif

    private func addScore(_ points: Int) {
        stats.score += points
        if stats.score > best {
            best = stats.score
        }
    }

    func update(dt: Double, input: InputState) -> [SimEvent] {
        phaseTime += dt
        switch phase {
        case .play:
            var events = sim.step(dt: dt, input: input)
            for event in events {
                switch event {
                case .barrelJumped:
                    addScore(ScoreRules.barrelJumpPoints)
                case .hit:
                    stats.lives = max(0, stats.lives - 1)
                    if stats.lives == 0 {
                        enter(.gameOver)
                        if let runID { completedRun = CompletedRun(id: runID, score: stats.score, levelReached: stats.levelIndex + 1) }
                        saveBest(best)
                        events.append(.gameOver)
                    } else {
                        enter(.lifeLost)
                        events.append(.lifeLost(livesLeft: stats.lives))
                    }
                case .rescued:
                    addScore(ScoreRules.levelCompletePoints)
                    saveBest(best)
                    enter(.levelComplete)
                    events.append(.levelComplete)
                default:
                    break
                }
            }
            return events
        case .lifeLost where phaseTime >= PlayTimings.lifeLoss:
            enter(.retrying)
            return []
        case .retrying where phaseTime >= PlayTimings.retry:
            // A hit retries the current level and keeps the score.
            sim.load(DifficultyRamp.level(at: stats.levelIndex))
            enter(.play)
            return [.retry]
        case .levelComplete where phaseTime >= PlayTimings.levelComplete:
            stats.levelIndex += 1
            sim.load(DifficultyRamp.level(at: stats.levelIndex))
            enter(.play)
            return [.levelStarted(stats.levelIndex)]
        default:
            return []
        }
    }
}
