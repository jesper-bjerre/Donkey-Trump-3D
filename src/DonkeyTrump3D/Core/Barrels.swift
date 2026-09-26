import Foundation

// Barrels spawn at the boss anchor moving right-to-left, roll downhill along the
// girders, drop to the girder below at each end, and may take a ladder down. Some
// are instead hurled straight at the player: they fly through the girders in an
// arc aimed at the player's x, land on the player's floor and roll on from there.

final class Barrel {
    enum Mode: Equatable { case thrown, falling, rolling, dropping }

    static let radius = 9.0

    let id: Int
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

    init(config: BarrelConfig, settings: BarrelSettings = BarrelSettings(), seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.config = config
        self.settings = settings
        self.random = SeededRandom(seed: seed)
        nextSpawnAt = config.firstSpawnDelayMs / 1000
    }

    var maxActive: Int { config.maxActive ?? 6 }
    var directThrowChance: Double { config.route?.directThrowChance ?? 0 }
    var ladderDropChance: Double { config.route?.ladderDropChance ?? 0 }

    /// Seconds until the next spawn, or nil when the next spawn will be skipped (too many barrels).
    var timeToNextSpawn: Double? {
        active.count < maxActive ? nextSpawnAt - elapsed : nil
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
        if elapsed >= nextSpawnAt {
            if active.count < maxActive { events.append(.spawned(spawn(at: spawnPoint, target: target))) }
            nextSpawnAt = elapsed + config.spawnIntervalMs / 1000
        }
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
        let plan = planDirectThrow(point, target: target)
        let barrel: Barrel
        if let reused = pool.popLast() {
            barrel = reused
        } else {
            barrel = Barrel(id: nextId)
            nextId += 1
        }
        barrel.x = point.x
        barrel.y = point.y
        barrel.active = true
        barrel.jumpAwarded = false
        barrel.speed = config.speedMin + random.next() * (config.speedMax - config.speedMin)
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
        if barrel.mode == .dropping {
            barrel.vx = 0
            barrel.vy = settings.ladderDropSpeed
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
                barrel.vx = barrel.direction * barrel.speed
                maybeTakeLadder(barrel, ladders: ladders)
            } else if barrel.mode == .rolling {
                barrel.mode = .falling
                barrel.vx = barrel.direction * barrel.speed * settings.fallSpeedFactor
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
        nextSpawnAt = config.firstSpawnDelayMs / 1000
    }
}
