import Foundation

enum ScoreRules {
    static let startingLives = 3
    static let levelCompletePoints = 1000
    static let barrelJumpPoints = 100
    /// Jumping several barrels in one leap pays a combo multiplier.
    static let comboBonusPerExtraBarrel = 100
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
