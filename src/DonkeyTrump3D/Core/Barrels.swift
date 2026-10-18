import Foundation

// Barrels spawn at the boss anchor moving right-to-left, roll downhill along the
// girders, drop to the girder below at each end, and may take a ladder down. Some
// are instead hurled straight at the player: they fly through the girders in an
// arc aimed at the player's x, land on the player's floor and roll on from there.

final class Barrel {
    enum Mode: Equatable { case thrown, falling, rolling, dropping }

    static let radius = 9.0

    let id: Int
    fileprivate(set) var lifetime = BarrelLifetimeID(runID: UUID(), attemptSerial: 0, spawnSerial: 0)
    fileprivate(set) var baseSpeed = 0.0
    var horizontalFallFactor = 1.0
    var directFlight = false
    var x = 0.0
    var y = 0.0
    var vx = 0.0
    var vy = 0.0
    var mode = Mode.falling
    var thrown = false
    var targetFeet: Double?
    var speed = 0.0
    var direction = -1.0
    var dropLadder: Int?
    var decidedLadders = Set<Int>()
    var jumpAwarded = false
    var active = false
    /// Visual roll angle in radians (counter-clockwise, seen from the camera).
    var rotation = 0.0

    init(id: Int) { self.id = id }

    var bounds: Bounds {
        Bounds(left: x - Barrel.radius, right: x + Barrel.radius, top: y - Barrel.radius, bottom: y + Barrel.radius)
    }
}

struct BarrelSettings {
    /// Horizontal speed kept while falling off a girder end, so the barrel lands on the girder below.
    var fallSpeedFactor = 0.25
    var ladderDropSpeed = 70.0
    /// Direct throws only target a player at least this far below the throw point.
    var directThrowMinDrop = 60.0
    var directThrowMaxSpeedX = 320.0
    /// The boss winds up this long before a barrel leaves his hands.
    var windup = 0.55
}

enum BarrelEvent {
    case spawned(Barrel)
    case landed(Barrel)
}

final class BarrelSystem {
    private(set) var config: BarrelConfig
    let settings: BarrelSettings
    private(set) var active: [Barrel] = []
    private var pool: [Barrel] = []
    private var nextId = 0
    private(set) var elapsed = 0.0
    private(set) var nextSpawnAt: Double
    private var random: SeededRandom
    private var runID = UUID()
    private var attemptSerial: UInt64 = 0
    private(set) var spawnSerial: UInt64 = 0
    private var speedMultiplier = 1.0
    private var releaseInterval: Double
    private var releaseProgress = 0.0
    private var hasFirstRelease = false

    func identify(runID: UUID, attemptSerial: UInt64) {
        self.runID = runID; self.attemptSerial = attemptSerial; spawnSerial = 0
    }

    func applyPressure(speedMultiplier: Double, interval: Double) {
        self.speedMultiplier = speedMultiplier
        releaseInterval = interval
    }

    init(config: BarrelConfig, settings: BarrelSettings = BarrelSettings(), seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.config = config
        self.releaseInterval = config.spawnIntervalMs / 1000
        self.settings = settings
        self.random = SeededRandom(seed: seed)
        nextSpawnAt = config.firstSpawnDelayMs / 1000
    }

    var maxActive: Int { config.maxActive ?? 6 }
    var directThrowChance: Double { config.route?.directThrowChance ?? 0 }
    var ladderDropChance: Double { config.route?.ladderDropChance ?? 0 }

    /// Seconds until the next spawn, or nil when the next spawn will be skipped (too many barrels).
    var timeToNextSpawn: Double? {
        active.count < maxActive ? (hasFirstRelease ? max(0, 1 - releaseProgress) * releaseInterval : max(0, config.firstSpawnDelayMs / 1000 - elapsed)) : nil
    }

    /// Horizontal speed that makes a barrel released at rest reach `target` when it has
    /// fallen to the target's feet: t = sqrt(2 * drop / g), vx = dx / t.
    static func directThrowVelocity(from: LevelPoint, targetX: Double, targetFeet: Double, maxSpeedX: Double) -> Double? {
        let drop = targetFeet - from.y
        guard drop > 0 else { return nil }
        let seconds = (2 * drop / Physics.gravity).squareRoot()
        let vx = (targetX - from.x) / seconds
        return max(-maxSpeedX, min(maxSpeedX, vx))
    }

    func update(dt: Double, spawnPoint: LevelPoint, target: (x: Double, feet: Double)?, segments: [Segment], ladders: [LevelLadder], world: LevelDimensions) -> [BarrelEvent] {
        var events: [BarrelEvent] = []
        elapsed += dt
        let due: Bool
        if !hasFirstRelease {
            due = elapsed >= config.firstSpawnDelayMs / 1000
        } else {
            releaseProgress += dt / releaseInterval
            due = releaseProgress >= 1
        }
        if due {
            hasFirstRelease = true; releaseProgress = 0
            if active.count < maxActive {
                let barrel = spawn(at: spawnPoint, target: target)
                if barrel.active { events.append(.spawned(barrel)) }
            }
        }
        nextSpawnAt = elapsed + (timeToNextSpawn ?? releaseInterval)
        for barrel in active {
            if step(barrel, dt: dt, segments: segments, ladders: ladders) { events.append(.landed(barrel)) }
            let b = barrel.bounds
            if b.right < 0 || b.left > world.width || b.top > world.height { recycle(barrel) }
        }
        active.removeAll { !$0.active }
        return events
    }

    private func planDirectThrow(_ point: LevelPoint, target: (x: Double, feet: Double)?) -> (vx: Double, feet: Double)? {
        guard directThrowChance > 0, let target, target.feet - point.y >= settings.directThrowMinDrop else { return nil }
        guard random.next() < directThrowChance else { return nil }
        guard let vx = BarrelSystem.directThrowVelocity(from: point, targetX: target.x, targetFeet: target.feet, maxSpeedX: settings.directThrowMaxSpeedX) else { return nil }
        return (vx, target.feet)
    }

    @discardableResult
    func spawn(at point: LevelPoint, target: (x: Double, feet: Double)? = nil) -> Barrel {
        guard spawnSerial < UInt64.max else { return Barrel(id: -1) }
        spawnSerial += 1
        let plan = planDirectThrow(point, target: target)
        let barrel: Barrel
        if let reused = pool.popLast() {
            barrel = reused
        } else {
            barrel = Barrel(id: nextId)
            nextId += 1
        }
        barrel.lifetime = BarrelLifetimeID(runID: runID, attemptSerial: attemptSerial, spawnSerial: spawnSerial)
        barrel.horizontalFallFactor = 1
        barrel.directFlight = plan != nil
        barrel.x = point.x
        barrel.y = point.y
        barrel.active = true
        barrel.jumpAwarded = false
        barrel.baseSpeed = config.speedMin + random.next() * (config.speedMax - config.speedMin)
        barrel.speed = barrel.baseSpeed * speedMultiplier
        barrel.direction = -1
        barrel.mode = plan == nil ? .falling : .thrown
        barrel.thrown = plan != nil
        barrel.targetFeet = plan?.feet
        barrel.dropLadder = nil
        barrel.decidedLadders = []
        barrel.rotation = 0
        barrel.vx = plan?.vx ?? -barrel.speed
        barrel.vy = 0
        active.append(barrel)
        return barrel
    }

    /// Advances one barrel. Returns true when it just touched down on a girder.
    private func step(_ barrel: Barrel, dt: Double, segments: [Segment], ladders: [LevelLadder]) -> Bool {
        var landed = false
        barrel.speed = barrel.baseSpeed * speedMultiplier
        if !barrel.directFlight && barrel.mode != .dropping {
            barrel.vx = barrel.direction * barrel.speed * (barrel.mode == .falling ? barrel.horizontalFallFactor : 1)
        }
        if barrel.mode == .dropping {
            barrel.vx = 0
            barrel.vy = settings.ladderDropSpeed * speedMultiplier
        } else {
            barrel.vy = min(barrel.vy + Physics.gravity * dt, Physics.maxFallSpeed)
        }
        barrel.x += barrel.vx * dt
        barrel.y += barrel.vy * dt
        let feet = barrel.y + Barrel.radius

        switch barrel.mode {
        case .thrown:
            // Flies through girders until it reaches the player's floor, then lands normally.
            if let target = barrel.targetFeet, feet >= target - 4 {
                barrel.mode = .falling
                barrel.direction = barrel.vx == 0 ? barrel.direction : (barrel.vx > 0 ? 1 : -1)
            }
        case .dropping:
            if let index = barrel.dropLadder {
                let ladder = ladders[index]
                if feet >= ladder.y + ladder.height - 1 {
                    barrel.y = ladder.y + ladder.height - Barrel.radius
                    barrel.mode = .falling
                    barrel.direction = -barrel.direction
                }
            }
        case .falling, .rolling:
            let contact = Slope.resolve(x: barrel.x, bottom: feet, velocityY: barrel.vy, segments: segments)
            if contact.grounded, let index = contact.segmentIndex {
                if barrel.mode == .falling { landed = true }
                barrel.y = contact.bottom - Barrel.radius
                barrel.vy = 0
                let downhill = segments[index].downhill
                if downhill != 0 { barrel.direction = downhill }
                barrel.mode = .rolling
                barrel.directFlight = false
                barrel.horizontalFallFactor = 1
                barrel.vx = barrel.direction * barrel.speed
                maybeTakeLadder(barrel, ladders: ladders)
            } else if barrel.mode == .rolling {
                barrel.mode = .falling
                barrel.horizontalFallFactor = settings.fallSpeedFactor
                barrel.vx = barrel.direction * barrel.speed * barrel.horizontalFallFactor
            }
        }

        // Thrown barrels tumble fast in the air; rolling ones turn with their speed.
        let spin = barrel.mode == .thrown ? (barrel.vx >= 0 ? 1.0 : -1.0) * 12 : barrel.vx / Barrel.radius
        barrel.rotation -= spin * dt
        return landed
    }

    private func maybeTakeLadder(_ barrel: Barrel, ladders: [LevelLadder]) {
        guard ladderDropChance > 0 else { return }
        let feet = barrel.y + Barrel.radius
        guard let index = ladders.firstIndex(where: { abs($0.snapX - barrel.x) <= 4 && abs($0.y - feet) <= 4 }),
              !barrel.decidedLadders.contains(index) else { return }
        barrel.decidedLadders.insert(index)
        if random.next() < ladderDropChance {
            barrel.mode = .dropping
            barrel.dropLadder = index
            barrel.x = ladders[index].snapX
        }
    }

    private func recycle(_ barrel: Barrel) {
        barrel.active = false
        barrel.vx = 0
        barrel.vy = 0
        pool.append(barrel)
    }

    func reset() {
        for barrel in active { recycle(barrel) }
        active.removeAll()
        elapsed = 0
        releaseProgress = 0; hasFirstRelease = false
        nextSpawnAt = config.firstSpawnDelayMs / 1000
    }
}
