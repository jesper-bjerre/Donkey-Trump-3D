import Foundation

enum ActiveDuration {
    static let second: Int64 = 1_000_000_000
    static let attempt: Int64 = 180 * second
    static func add(_ a: Int64, _ b: Int64) -> Int64? {
        guard a >= 0, b >= 0 else { return nil }
        let (value, overflow) = a.addingReportingOverflow(b)
        return overflow ? nil : value
    }
    static func displaySeconds(_ ns: Int64) -> Int {
        Int(ns / second + (ns % second > 0 ? 1 : 0))
    }
}

struct BarrelLifetimeID: Hashable, Comparable {
    let runID: UUID
    let attemptSerial: UInt64
    let spawnSerial: UInt64
    static func < (a: Self, b: Self) -> Bool {
        if a.runID != b.runID { return a.runID.uuidString < b.runID.uuidString }
        if a.attemptSerial != b.attemptSerial { return a.attemptSerial < b.attemptSerial }
        return a.spawnSerial < b.spawnSerial
    }
}

enum LifeLossReason: Equatable { case timeout, collision }
enum TerminalReason: Int { case timeout, collision, rescue }
enum AttemptOutcome: Equatable { case active, lifeLost(LifeLossReason), completed }

struct AttemptState {
    let attemptSerial: UInt64
    var spawnSerial: UInt64 = 0 // copied from this attempt's BarrelSystem release counter
    var remainingNs = ActiveDuration.attempt
    var outcome: AttemptOutcome = .active
    var terminalAt: Int64?
}

struct LevelProgress {
    let visibleLevel: Int
    let baseBarrelConfiguration: BarrelConfig
    var totalActiveNs: Int64 = 0
    var rewardedLifetimes: Set<BarrelLifetimeID> = []
    var completionReward: LevelRewardBreakdown?
    let minimumReleaseInterval: Double

    init(level: Level) {
        visibleLevel = level.order
        baseBarrelConfiguration = level.barrels
        let slope = level.girders.map { girder in
            let segment = Segment(girder)
            return abs((segment.y2 - segment.y1) / (segment.x2 - segment.x1))
        }.max() ?? 0
        minimumReleaseInterval = ScoreRules.minimumInterval(baseSpeed: level.barrels.speedMin, slope: slope)
    }

    var pressure: Double { min(1, max(0, Double(totalActiveNs) / Double(ActiveDuration.attempt))) }
    var speedMultiplier: Double { 1 + 0.25 * pressure }
    var desiredInterval: Double { baseBarrelConfiguration.spawnIntervalMs / 1000 * (1 - 0.60 * pressure) }
    var actualInterval: Double { max(desiredInterval, minimumReleaseInterval) }
}

struct ClearanceCandidate {
    let lifetime: BarrelLifetimeID
    let registeredAtNs: Int64 // cumulative active level T, never adapter-origin time
    let position: LevelPoint
}

struct TerminalCandidate {
    let runID: UUID
    let attemptSerial: UInt64
    let registeredAtNs: Int64
    let reason: TerminalReason
}

struct ScoreAward {
    enum Source { case barrel, completion, time }
    let lifetime: BarrelLifetimeID // spawnSerial 0 denotes a level reward
    let registeredAtNs: Int64
    let source: Source
    let points: Int
    let position: LevelPoint
}

struct LevelRewardBreakdown: Equatable {
    let visibleLevel: Int
    let completionPoints: Int
    let bonusSeconds: Int
    let timePoints: Int
    let totalAfterCompletion: Int
}

struct LifeLossSnapshot {
    let reason: LifeLossReason
    let remainingLives: Int
    let runID: UUID
    let attemptSerial: UInt64
}

/// Copies all delayed effect data; pooling can no longer rewrite an old event.
struct BarrelSnapshot {
    let id: Int
    let lifetime: BarrelLifetimeID
    let x: Double
    let y: Double
    let thrown: Bool
    init(_ barrel: Barrel) {
        id = barrel.id; lifetime = barrel.lifetime
        x = barrel.x; y = barrel.y; thrown = barrel.thrown
    }
}
