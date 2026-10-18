import Foundation

enum ScoreRules {
    static let startingLives = 3
    static func barrel(level: Int) -> Int? { multiply(10, level) }
    static func completion(level: Int) -> Int? { multiply(1000, level) }
    static func bonusSeconds(totalActiveNs: Int64) -> Int {
        Int(max(0, ActiveDuration.attempt - max(0, totalActiveNs)) / ActiveDuration.second)
    }
    static func time(level: Int, totalActiveNs: Int64) -> Int? {
        guard let perSecond = multiply(5, level) else { return nil }
        return multiply(perSecond, bonusSeconds(totalActiveNs: totalActiveNs))
    }
    private static func multiply(_ a: Int, _ b: Int) -> Int? {
        guard a >= 0, b >= 0 else { return nil }
        let (value, overflow) = a.multipliedReportingOverflow(by: b)
        return overflow ? nil : value
    }
    static func minimumInterval(baseSpeed: Double, slope: Double) -> Double {
        let player = PlayerSettings()
        let jump = (2 * player.jumpVelocity + 2 * player.moveSpeed * abs(slope)) / Physics.gravity
        return ceil(10 * (jump * (baseSpeed + player.moveSpeed) / baseSpeed + 0.10)) / 10
    }
}

enum PlayTimings {
    static let lifeLoss = 1.4
    static let retry = 0.6
    static let levelComplete = 3.2
}

/// Game flow phases. The web game's state machine, plus title and intro.
enum GamePhase: Equatable {
    case title
    case intro
    case play
    case paused
    case lifeLost
    case retrying
    case levelComplete
    case gameOver
}

struct ScoreLives: Equatable {
    var score = 0
    var lives = ScoreRules.startingLives
    var levelIndex = 0
}

/// Input for one simulation step, merged from touch, game controller and keyboard.
struct InputState: Equatable {
    var left = false
    var right = false
    var up = false
    var down = false
    var jumpHeld = false
    var jumpPressed = false

    var any: Bool { left || right || up || down || jumpHeld }
}

/// Deterministic PRNG so tests (and the autopilot demo) are reproducible.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1_000_000) / 1_000_000
    }
}
