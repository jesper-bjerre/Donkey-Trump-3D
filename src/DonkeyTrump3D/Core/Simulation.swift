import Foundation

enum SimEvent {
    case jump
    case ladderExit
    case barrelThrown(BarrelSnapshot)
    case barrelLanded(BarrelSnapshot)
    case barrelJumped(BarrelSnapshot)
    case hit(BarrelSnapshot)
    case rescued
    case scoreAward(ScoreAward)
    case lost(LifeLossSnapshot)
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
            case .spawned(let b): events.append(.barrelThrown(BarrelSnapshot(b)))
            case .landed(let b): events.append(.barrelLanded(BarrelSnapshot(b)))
            }
        }

        let pb = player.bounds
        if player.isAirborne {
            for barrel in barrels.active where !barrel.jumpAwarded {
                let b = barrel.bounds
                let underFeet = b.top >= pb.bottom - 2 && b.top - pb.bottom <= GameSimulation.jumpDetectHeight
                if underFeet && pb.centerX >= b.left && pb.centerX <= b.right {
                    barrel.jumpAwarded = true
                    events.append(.barrelJumped(BarrelSnapshot(barrel)))
                }
            }
        }

        if time >= invulnerableUntil {
            let hitbox = pb.inset(GameSimulation.hitboxInset)
            if let barrel = barrels.active.first(where: { hitbox.overlaps($0.bounds.inset(GameSimulation.hitboxInset)) }) {
                invulnerableUntil = time + GameSimulation.hitCooldown
                player.setHit()
                events.append(.hit(BarrelSnapshot(barrel)))
            }
        }

        if !rescued && pb.overlaps(rescueZone) {
            rescued = true
            events.append(.rescued)
        }
        return events
    }
}

/// Owns all run, level and attempt mutations. Rendering only consumes copied events.
final class GameSession {
    private(set) var runID: UUID?
    private(set) var completedRun: CompletedRun?
    private(set) var phase: GamePhase = .title
    private(set) var stats = ScoreLives()
    private(set) var phaseTime = 0.0
    private var phaseNs: Int64 = 0
    private var durationRemainder = 0.0
    private(set) var best: Int
    private(set) var levelProgress: LevelProgress?
    private(set) var attempt: AttemptState?
    private(set) var lastLossReason: LifeLossReason?
    private(set) var scoringValid = true
    private var attemptSerial: UInt64 = 0
    let sim: GameSimulation
    private let saveBest: (Int) -> Void

    init(seed: UInt64 = UInt64.random(in: 1...UInt64.max), best: Int = 0, saveBest: @escaping (Int) -> Void = { _ in }) {
        sim = GameSimulation(level: DifficultyRamp.level(at: 0), seed: seed)
        self.best = best; self.saveBest = saveBest
    }
    var level: Level { sim.level }
    private func enter(_ next: GamePhase) { phase = next; phaseNs = 0; phaseTime = 0 }

    private func freshAttempt(newLevel: Bool) {
        guard let runID, attemptSerial < UInt64.max else { scoringValid = false; enter(.gameOver); return }
        attemptSerial += 1
        sim.load(DifficultyRamp.level(at: stats.levelIndex))
        if newLevel { levelProgress = LevelProgress(level: sim.level) }
        attempt = AttemptState(attemptSerial: attemptSerial)
        sim.barrels.identify(runID: runID, attemptSerial: attemptSerial)
        applyPressure()
    }
    private func newRun() {
        runID = UUID(); completedRun = nil; stats = ScoreLives(); attemptSerial = 0
        levelProgress = nil; attempt = nil; lastLossReason = nil; scoringValid = true; durationRemainder = 0
    }
    func showTitle() {
        runID = nil; completedRun = nil; levelProgress = nil; attempt = nil
        sim.load(DifficultyRamp.level(at: 0)); enter(.title)
    }
    func startNewGame() { newRun(); sim.load(DifficultyRamp.level(at: 0)); enter(.intro) }
    func beginPlay() -> [SimEvent] {
        guard phase == .intro || phase == .title else { return [] }
        if runID == nil { newRun() }
        freshAttempt(newLevel: true); enter(.play)
        return [.levelStarted(stats.levelIndex)]
    }
    func pause() { if phase == .play { phase = .paused } }
    func resume() { if phase == .paused { phase = .play } }
    func restart() -> [SimEvent] {
        newRun(); freshAttempt(newLevel: true); enter(.play)
        return [.levelStarted(0)]
    }

    #if DEBUG
    @discardableResult
    func install(_ fixture: GameplayFixtureLaunch) -> Bool {
        newRun(); stats.levelIndex = fixture.levelIndex; freshAttempt(newLevel: true)
        levelProgress?.totalActiveNs = fixture.retainedNs; applyPressure()
        if fixture.levelIndex >= 999 {
            let b = sim.level.barrels
            guard b.speedMin == 240, b.speedMax == 280, b.spawnIntervalMs == 800,
                  b.maxActive == 12, b.route?.directThrowChance == 0.55 else { showTitle(); return false }
        }
        guard let top = sim.segments.last else { showTitle(); return false }
        for x in stride(from: top.x1 + Player.width, through: top.x2 - Player.width, by: 20) {
            sim.player.reset(spawn: .init(x: x, y: top.y(at: x)))
            sim.player.applySlope(segments: sim.segments, now: 0)
            if sim.player.isGrounded && !sim.player.bounds.overlaps(sim.rescueZone) {
                enter(.play); return true
            }
        }
        showTitle(); return false
    }
    func completeForHighscoreFixture(_ run: CompletedRun) {
        runID = run.id; completedRun = run
        stats.score = run.score; stats.levelIndex = run.levelReached - 1; stats.lives = 0
        best = max(best, run.score); saveBest(best)
        levelProgress = nil; attempt = nil
        sim.load(DifficultyRamp.level(at: stats.levelIndex)); enter(.gameOver)
    }
    #endif

    private func applyPressure() {
        guard let progress = levelProgress else { return }
        sim.barrels.applyPressure(speedMultiplier: progress.speedMultiplier, interval: progress.actualInterval)
    }
    private func addScore(_ value: Int?) -> Bool {
        guard scoringValid, let value, value >= 0 else { scoringValid = false; return false }
        let (total, overflow) = stats.score.addingReportingOverflow(value)
        guard !overflow else { scoringValid = false; return false }
        stats.score = total; best = max(best, total)
        return true
    }

    /// Pure candidate arbitration, shared by the real simulation and deterministic checks.
    /// through and registration stamps are cumulative active T for this attempt.
    func resolve(candidates: [TerminalCandidate], clearances: [ClearanceCandidate], through: Int64? = nil) -> [SimEvent] {
        guard phase == .play, let runID, var a = attempt, a.outcome == .active, var p = levelProgress else { return [] }
        a.spawnSerial = sim.barrels.spawnSerial
        let start = p.totalActiveNs
        guard let maximum = ActiveDuration.add(start, a.remainingNs) else { scoringValid = false; return [] }
        let end = min(maximum, max(start, through ?? start))
        var valid = candidates.filter { $0.runID == runID && $0.attemptSerial == a.attemptSerial && $0.registeredAtNs >= start && $0.registeredAtNs <= end }
        if end == maximum { valid.append(.init(runID: runID, attemptSerial: a.attemptSerial, registeredAtNs: end, reason: .timeout)) }
        let terminal = valid.min { $0.registeredAtNs == $1.registeredAtNs ? $0.reason.rawValue < $1.reason.rawValue : $0.registeredAtNs < $1.registeredAtNs }
        let stop = terminal?.registeredAtNs ?? end
        p.totalActiveNs = stop; a.remainingNs -= stop - start
        var events: [SimEvent] = []
        for c in clearances.sorted(by: { $0.registeredAtNs == $1.registeredAtNs ? $0.lifetime < $1.lifetime : $0.registeredAtNs < $1.registeredAtNs }) {
            guard c.lifetime.runID == runID, c.lifetime.attemptSerial == a.attemptSerial,
                  c.registeredAtNs >= start, c.registeredAtNs <= stop,
                  terminal == nil || terminal?.reason == .rescue || c.registeredAtNs < stop,
                  p.rewardedLifetimes.count < 20, !p.rewardedLifetimes.contains(c.lifetime) else { continue }
            let points = ScoreRules.barrel(level: p.visibleLevel)
            if addScore(points), let points {
                p.rewardedLifetimes.insert(c.lifetime)
                events.append(.scoreAward(.init(lifetime: c.lifetime, registeredAtNs: c.registeredAtNs, source: .barrel, points: points, position: c.position)))
            }
        }
        if let terminal {
            a.terminalAt = stop
            if terminal.reason == .rescue {
                a.outcome = .completed
                if p.completionReward == nil,
                   let completion = ScoreRules.completion(level: p.visibleLevel),
                   let time = ScoreRules.time(level: p.visibleLevel, totalActiveNs: stop) {
                    let (sum, overflow) = completion.addingReportingOverflow(time)
                    if !overflow && addScore(sum) {
                        p.completionReward = .init(visibleLevel: p.visibleLevel, completionPoints: completion,
                            bonusSeconds: ScoreRules.bonusSeconds(totalActiveNs: stop), timePoints: time, totalAfterCompletion: stats.score)
                        let id = BarrelLifetimeID(runID: runID, attemptSerial: a.attemptSerial, spawnSerial: 0)
                        let pos = LevelPoint(x: sim.level.rescue.x, y: sim.level.rescue.y)
                        events.append(.scoreAward(.init(lifetime: id, registeredAtNs: stop, source: .completion, points: completion, position: pos)))
                        if time > 0 { events.append(.scoreAward(.init(lifetime: id, registeredAtNs: stop, source: .time, points: time, position: .init(x: pos.x, y: pos.y - 30)))) }
                    } else { scoringValid = false }
                } else if p.completionReward == nil { scoringValid = false }
                saveBest(best); enter(.levelComplete); events.append(.levelComplete)
            } else {
                let reason: LifeLossReason = terminal.reason == .timeout ? .timeout : .collision
                a.outcome = .lifeLost(reason); lastLossReason = reason
                stats.lives = max(0, stats.lives - 1)
                events.append(.lost(.init(reason: reason, remainingLives: stats.lives, runID: runID, attemptSerial: a.attemptSerial)))
                if stats.lives == 0 {
                    enter(.gameOver)
                    if scoringValid { completedRun = .init(id: runID, score: stats.score, levelReached: p.visibleLevel) }
                    saveBest(best); events.append(.gameOver)
                } else { enter(.lifeLost); events.append(.lifeLost(livesLeft: stats.lives)) }
            }
        }
        levelProgress = p; attempt = a; applyPressure()
        return events
    }

    func update(dt: Double, input: InputState) -> [SimEvent] {
        guard dt.isFinite, dt >= 0, dt < Double(Int64.max) / 1e9 else { return [] }
        let exact = dt * 1e9 + durationRemainder
        let ns = Int64(exact.rounded(.down)); durationRemainder = exact - Double(ns)
        return update(ns: ns, input: input)
    }
    func update(ns: Int64, input: InputState) -> [SimEvent] {
        guard ns >= 0 else { return [] }
        switch phase {
        case .play:
            guard let a = attempt, let p = levelProgress, let id = runID,
                  let end = ActiveDuration.add(p.totalActiveNs, min(ns, a.remainingNs)) else { return [] }
            applyPressure()
            let raw = sim.step(dt: Double(min(ns, a.remainingNs)) / 1e9, input: input)
            var terminals: [TerminalCandidate] = [], clearances: [ClearanceCandidate] = []
            for event in raw {
                switch event {
                case .barrelJumped(let b): clearances.append(.init(lifetime: b.lifetime, registeredAtNs: end, position: .init(x: b.x, y: b.y)))
                case .hit: terminals.append(.init(runID: id, attemptSerial: a.attemptSerial, registeredAtNs: end, reason: .collision))
                case .rescued: terminals.append(.init(runID: id, attemptSerial: a.attemptSerial, registeredAtNs: end, reason: .rescue))
                default: break
                }
            }
            return raw.filter { if case .barrelJumped = $0 { return false }; if case .hit = $0 { return false }; if case .rescued = $0 { return false }; return true }
                + resolve(candidates: terminals, clearances: clearances, through: end)
        case .lifeLost, .retrying, .levelComplete:
            guard let next = ActiveDuration.add(phaseNs, ns) else { return [] }
            phaseNs = next; phaseTime = Double(next) / 1e9
            if phase == .lifeLost && next >= 1_400_000_000 { enter(.retrying) }
            else if phase == .retrying && next >= 600_000_000 { freshAttempt(newLevel: false); enter(.play); return [.retry] }
            else if phase == .levelComplete && next >= 3_200_000_000 {
                guard stats.levelIndex < Int.max - 1 else { scoringValid = false; enter(.gameOver); return [] }
                stats.levelIndex += 1; freshAttempt(newLevel: true); enter(.play); return [.levelStarted(stats.levelIndex)]
            }
            return []
        default: return []
        }
    }
}
