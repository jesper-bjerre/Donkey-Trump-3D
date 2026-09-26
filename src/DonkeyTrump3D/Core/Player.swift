import Foundation

/// World physics shared by the player and barrels (level pixels per second).
enum Physics {
    static let gravity = 500.0
    /// Caps fall speed so a body never sinks further than the slope tolerance in one step.
    static let maxFallSpeed = 600.0
    static let maxSpeedX = 400.0
}

enum PlayerMode: Equatable {
    case normal, jumping, climbing, hit
}

struct PlayerSettings {
    var moveSpeed = 120.0
    var jumpVelocity = 210.0
    /// Upward velocity is multiplied by this when jump is released early.
    var jumpCutMultiplier = 0.45
    var coyoteTime = 0.08
    var climbSpeed = 90.0
    /// Vertical slack so a player standing exactly on a ladder end still overlaps it.
    var ladderPadding = 6.0
    /// Holding up/down while airborne over a ladder grabs it at the current height.
    var grabMidAir = true

    /// Apex of a full jump: v^2 / 2g. It must stay below every floor gap.
    var jumpApex: Double { jumpVelocity * jumpVelocity / (2 * Physics.gravity) }
}

/// Jumpman Løkke: horizontal movement, the deliberately short jump and overlap-gated
/// ladder climbing. Position is the body's center x and feet y.
final class Player {
    static let width = 22.0
    static let height = 45.0
    private static let endEpsilon = 1.0

    var settings = PlayerSettings()
    var x = 0.0
    var feet = 0.0
    var vx = 0.0
    var vy = 0.0
    private(set) var mode = PlayerMode.normal
    private(set) var grounded = false
    private var lastGroundedAt = -Double.infinity
    private var jumpCut = false
    private(set) var facing = 1.0
    private(set) var activeLadder: Int?
    /// Girder the player last stood on.
    private(set) var floor: Int?

    var bounds: Bounds {
        Bounds(left: x - Player.width / 2, right: x + Player.width / 2, top: feet - Player.height, bottom: feet)
    }

    var isClimbing: Bool { activeLadder != nil }
    var isGrounded: Bool { grounded }
    var isAirborne: Bool { !grounded && !isClimbing }

    func reset(spawn: LevelPoint) {
        x = spawn.x
        feet = spawn.y
        vx = 0
        vy = 0
        mode = .normal
        grounded = false
        lastGroundedAt = -.infinity
        jumpCut = false
        facing = 1
        activeLadder = nil
        floor = nil
    }

    func setHit() {
        mode = .hit
        vx = 0
        vy = 0
        activeLadder = nil
    }

    // MARK: Ladders

    static func overlappingLadder(_ b: Bounds, ladders: [LevelLadder], padding: Double) -> Int? {
        var best: Int?
        for (i, l) in ladders.enumerated() {
            let overlaps = b.right > l.x && b.left < l.x + l.width && b.bottom >= l.y - padding && b.top <= l.y + l.height + padding
            guard overlaps else { continue }
            if let current = best, abs(ladders[current].snapX - b.centerX) <= abs(l.snapX - b.centerX) { continue }
            best = i
        }
        return best
    }

    /// Returns true when the player just stepped off a ladder end.
    @discardableResult
    func updateLadder(_ input: InputState, ladders: [LevelLadder]) -> Bool {
        guard mode != .hit else { return false }
        let overlapping = Player.overlappingLadder(bounds, ladders: ladders, padding: settings.ladderPadding)
        guard let index = activeLadder else {
            if let candidate = overlapping, shouldEnter(ladders[candidate], input) { enterLadder(candidate, ladders[candidate]) }
            return false
        }
        let ladder = ladders[index]
        if input.jumpPressed || overlapping != index {
            exitLadder()
            return false
        }
        vx = 0
        let speed = ladder.climbSpeedOverride ?? settings.climbSpeed
        if input.up && feet <= ladder.y + Player.endEpsilon {
            feet = ladder.y
            exitLadder()
            land()
            return true
        } else if input.down && feet >= ladder.y + ladder.height - Player.endEpsilon {
            feet = ladder.y + ladder.height
            exitLadder()
            land()
            return true
        }
        vy = input.up ? -speed : (input.down ? speed : 0)
        return false
    }

    private func shouldEnter(_ ladder: LevelLadder, _ input: InputState) -> Bool {
        guard input.up || input.down else { return false }
        if isAirborne && !settings.grabMidAir { return false }
        if input.up { return feet > ladder.y + Player.endEpsilon }
        return feet < ladder.y + ladder.height - Player.endEpsilon
    }

    private func enterLadder(_ index: Int, _ ladder: LevelLadder) {
        activeLadder = index
        mode = .climbing
        grounded = false
        vx = 0
        vy = 0
        x = ladder.snapX
    }

    private func exitLadder() {
        activeLadder = nil
        vy = 0
        if mode == .climbing { mode = .normal }
    }

    private func land() {
        grounded = true
    }

    // MARK: Movement

    /// Returns true when a jump started this step.
    @discardableResult
    func updateMovement(_ input: InputState, now: Double) -> Bool {
        guard mode == .normal || mode == .jumping else { return false }
        let direction = (input.right ? 1.0 : 0) - (input.left ? 1.0 : 0)
        vx = direction * settings.moveSpeed
        if direction != 0 { facing = direction }
        var jumped = false
        if input.jumpPressed { jumped = jump(now: now) }
        if !input.jumpHeld { cutJump() }
        return jumped
    }

    private func canJump(now: Double) -> Bool {
        mode == .normal && (grounded || now - lastGroundedAt <= settings.coyoteTime)
    }

    private func jump(now: Double) -> Bool {
        guard canJump(now: now) else { return false }
        vy = -settings.jumpVelocity
        mode = .jumping
        grounded = false
        jumpCut = false
        // Consume coyote time so an airborne press cannot trigger a second jump.
        lastGroundedAt = -.infinity
        return true
    }

    private func cutJump() {
        guard mode == .jumping, vy < 0, !jumpCut else { return }
        jumpCut = true
        vy *= settings.jumpCutMultiplier
    }

    // MARK: Integration

    func integrate(dt: Double, world: LevelDimensions) {
        if !isClimbing && mode != .hit {
            vy = min(vy + Physics.gravity * dt, Physics.maxFallSpeed)
        }
        vx = max(-Physics.maxSpeedX, min(Physics.maxSpeedX, vx))
        x += vx * dt
        feet += vy * dt
        x = max(Player.width / 2, min(world.width - Player.width / 2, x))
        if feet > world.height {
            feet = world.height
            vy = 0
        }
    }

    /// Snaps the feet onto the girder below (skipped while climbing, so ladders pass through girders).
    func applySlope(segments: [Segment], now: Double) {
        guard !isClimbing, mode != .hit else { return }
        let contact = Slope.resolve(x: x, bottom: feet, velocityY: vy, segments: segments)
        if contact.grounded {
            feet = contact.bottom
            if vy > 0 { vy = 0 }
            floor = contact.segmentIndex
        }
        grounded = contact.grounded
        if grounded {
            lastGroundedAt = now
            if mode == .jumping { mode = .normal }
        }
    }
}
