import Foundation

/// A simple bot that plays a level: walk to the ladder up, climb, repeat, then walk
/// to Motzfeldt, jumping barrels on the way. Drives the title-screen demo and the
/// `-autopilot` launch argument used for automated playtests.
struct Autopilot {
    private var linksLevelId = ""
    private var links: [LadderLink] = []
    private var jumpHold = 0.0
    private var cooldown = 0.0

    mutating func input(for sim: GameSimulation, dt: Double) -> InputState {
        if linksLevelId != sim.level.id {
            linksLevelId = sim.level.id
            links = IntroTimeline.ladderLinks(sim.level)
        }
        var input = InputState()
        let player = sim.player
        cooldown = max(0, cooldown - dt)

        if jumpHold > 0 {
            jumpHold -= dt
            input.jumpHeld = true
        }

        if let index = player.activeLadder {
            // Hold still below the top while a barrel rolls over the ladder head.
            let ladder = sim.level.ladders[index]
            if player.feet - ladder.y < 60 && barrelNear(ladder, sim) { return input }
            input.up = true
            return input
        }

        let top = sim.segments.count - 1
        let floor = player.floor ?? Slope.floorIndex(x: player.x, footY: player.feet, segments: sim.segments) ?? 0
        var targetX: Double
        var climb = false
        if floor >= top {
            targetX = sim.level.rescue.x + sim.level.rescue.width / 2
        } else if let link = links
            .filter({ $0.bottom == floor && $0.top == floor + 1 })
            .min(by: { abs($0.ladder.snapX - player.x) < abs($1.ladder.snapX - player.x) }) {
            targetX = link.ladder.snapX
            climb = true
        } else {
            targetX = player.x
        }

        let dx = targetX - player.x
        if abs(dx) <= 2.5 {
            if climb, let link = links.first(where: { $0.ladder.snapX == targetX && $0.bottom == floor }), !barrelNear(link.ladder, sim) {
                input.up = true
            }
        } else {
            input.right = dx > 0
            input.left = dx < 0
        }

        // Jump barrels rolling toward us on our floor.
        if player.isGrounded && cooldown == 0 {
            for barrel in sim.barrels.active where barrel.mode == .rolling || barrel.mode == .falling {
                let feetGap = abs(barrel.y + Barrel.radius - player.feet)
                guard feetGap < 16 else { continue }
                let gap = barrel.x - player.x
                let approaching = (gap > 0 && barrel.vx < 0) || (gap < 0 && barrel.vx > 0)
                let closing = abs(barrel.vx) + (input.left || input.right ? player.settings.moveSpeed : 0)
                let timeToContact = (abs(gap) - 16) / max(closing, 1)
                if approaching && timeToContact < 0.32 && timeToContact > 0 {
                    input.jumpPressed = true
                    input.jumpHeld = true
                    input.up = false
                    jumpHold = 0.5
                    cooldown = 0.7
                    break
                }
            }
        }
        return input
    }

    /// A barrel on the floor above that will cross this ladder's head soon.
    private func barrelNear(_ ladder: LevelLadder, _ sim: GameSimulation) -> Bool {
        sim.barrels.active.contains { b in
            let onTop = abs(b.y + Barrel.radius - ladder.y) < 16 || (b.mode == .dropping && b.dropLadder != nil)
            let dx = b.x - ladder.snapX
            let approaching = dx * b.vx < 0 || abs(dx) < 24
            return onTop && abs(dx) < 110 && approaching
        }
    }
}
