import Testing
@testable import DonkeyTrump3D

@Suite("Real simulation pressure sequences")
struct DifficultySequenceTests {
    // Search bounded input timings for a physically possible pair of jumps.
    // A failed arbitrary button timing alone would not prove an impossible sequence.
    @Test func representativeRollingDirectAndMixedLandingWindows() {
        for index in [0, 1, 2, 999, 1000, 1001] {
            for seed: UInt64 in [7, 91, 2026] {
                for direction in [-1.0, 1.0] {
                    for held in [false, true] {
                        for route in [0, 1, 2] { // rolling / direct / convergent mixed
                            let possible = stride(from: 0, through: 120, by: 4).contains { delay in
                                canLandAndJumpAgain(index: index, seed: seed, direction: direction,
                                                    held: held, route: route, jumpAt: delay)
                            }
                            #expect(possible, "index \(index), seed \(seed), direction \(direction), held \(held), route \(route)")
                        }
                    }
                }
            }
        }
    }

    private func canLandAndJumpAgain(index: Int, seed: UInt64, direction: Double,
                                    held: Bool, route: Int, jumpAt: Int) -> Bool {
        var level = DifficultyRamp.level(at: index)
        level.barrels.firstSpawnDelayMs = 1_000_000
        // Force the intended direct route rather than relying on a seed's probability draw.
        level.barrels.route?.directThrowChance = route == 0 ? 0 : 1
        let sim = GameSimulation(level: level, seed: seed)
        // This upper-half floor is far enough below the throw point for a real direct throw.
        let floor = sim.segments[sim.segments.count - 3]
        sim.player.reset(spawn: .init(x: 400, y: floor.y(at: 400)))
        for _ in 0..<4 { _ = sim.step(dt: 1.0 / 120, input: .init()) }
        let progress = LevelProgress(level: level)
        sim.barrels.applyPressure(speedMultiplier: 1.25, interval: progress.minimumReleaseInterval)
        if route != 1 {
            let travel = floor.downhill == 0 ? -1 : floor.downhill
            let x = 400 - travel * 95
            let barrel = sim.barrels.spawn(at: .init(x: x, y: floor.y(at: x) - Barrel.radius))
            barrel.direction = travel; barrel.mode = .rolling
        }
        if route != 0 {
            let point = sim.barrelSpawnPoint
            let barrel = sim.barrels.spawn(at: point, target: (400, floor.y(at: 400)))
            guard barrel.directFlight else { return false }
        }
        var airborne = false, landed = false, jumpedAgain = false
        var jumpStart = jumpAt
        for frame in 0..<300 {
            let press = frame == jumpAt || landed && !jumpedAgain
            if press { jumpStart = frame }
            let input = InputState(left: direction < 0, right: direction > 0,
                                   jumpHeld: frame >= jumpStart && (held || frame - jumpStart < 6),
                                   jumpPressed: press)
            let events = sim.step(dt: 1.0 / 120, input: input)
            if events.contains(where: { if case .hit = $0 { return true }; return false }) { return false }
            if landed && events.contains(where: { if case .jump = $0 { return true }; return false }) { jumpedAgain = true }
            airborne = airborne || sim.player.isAirborne
            if airborne && sim.player.isGrounded { landed = true }
        }
        return airborne && landed && jumpedAgain
    }
}
