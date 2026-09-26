import Foundation

// Level data shares the web game's JSON format and its coordinate space:
// 800 x 600 "level pixels", y pointing down. Rendering maps it into 3D.

struct LevelPoint: Codable, Equatable {
    var x: Double
    var y: Double
}

struct LevelGirder: Codable, Equatable {
    var id: String
    var x1: Double
    var y1: Double
    var x2: Double
    var y2: Double
    var collisionMode: String?
}

struct LevelLadder: Codable, Equatable {
    var id: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var snapX: Double
    var climbSpeedOverride: Double?
}

struct LevelBoss: Codable, Equatable {
    var x: Double
    var y: Double
    var spawnAnchorOffset: LevelPoint
}

struct BarrelRoute: Codable, Equatable {
    var ladderDropChance: Double?
    var directThrowChance: Double?
}

struct BarrelConfig: Codable, Equatable {
    var spawnIntervalMs: Double
    var firstSpawnDelayMs: Double
    var speedMin: Double
    var speedMax: Double
    var maxActive: Int?
    var route: BarrelRoute?
}

struct LevelRescue: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var isFinalLevel: Bool
}

struct LevelDifficulty: Codable, Equatable {
    var tier: Int
    var label: String
}

struct LevelDimensions: Codable, Equatable {
    var width: Double
    var height: Double
}

struct Level: Codable, Equatable {
    var id: String
    var name: String
    var order: Int
    var dimensions: LevelDimensions
    var playerSpawn: LevelPoint
    var girders: [LevelGirder]
    var ladders: [LevelLadder]
    var boss: LevelBoss
    var barrels: BarrelConfig
    var rescue: LevelRescue
    var difficulty: LevelDifficulty

    /// Index of the authored layout (0, 1, 2) this level was built from. Drives the theme.
    var layoutIndex: Int = 0

    private enum CodingKeys: String, CodingKey {
        case id, name, order, dimensions, playerSpawn, girders, ladders, boss, barrels, rescue, difficulty
    }
}

enum LevelLibrary {
    /// The three authored layouts, loaded once from the bundle.
    static let layouts: [Level] = {
        (1...3).map { n in
            guard let url = Bundle.main.url(forResource: "level\(n)", withExtension: "json")
                ?? Bundle(for: BundleToken.self).url(forResource: "level\(n)", withExtension: "json"),
                let data = try? Data(contentsOf: url),
                var level = try? JSONDecoder().decode(Level.self, from: data)
            else { fatalError("Missing or invalid level\(n).json") }
            level.layoutIndex = n - 1
            return level
        }
    }()
}

private final class BundleToken {}

// Endless mode: the authored layouts repeat forever and every cleared level makes
// the barrels faster, more frequent and more often hurled. Each value approaches a
// fair limit, so difficulty rises on every level without becoming impossible.
enum DifficultyRamp {
    static let retainPerLevel = 0.92
    static let speedMaxLimit = 280.0
    static let speedMinLimit = 240.0
    static let spawnIntervalLimitMs = 800.0
    static let directThrowChanceLimit = 0.55
    static let maxActiveCap = 12

    private static func approach(_ start: Double, _ limit: Double, _ levels: Int) -> Double {
        limit + (start - limit) * pow(retainPerLevel, Double(levels))
    }

    private static func round2(_ v: Double) -> Double { (v * 100).rounded() / 100 }

    static func level(at index: Int, layouts: [Level] = LevelLibrary.layouts) -> Level {
        let base = layouts[index % layouts.count]
        let loop = index / layouts.count
        let cleared = max(0, index - (layouts.count - 1))
        let tuning = cleared == 0 ? base.barrels : layouts[layouts.count - 1].barrels
        var level = base
        level.id = loop == 0 ? base.id : "\(base.id)-loop-\(loop + 1)"
        level.order = index + 1
        level.difficulty = LevelDifficulty(tier: index + 1, label: loop == 0 ? base.difficulty.label : "\(base.difficulty.label) +\(loop)")
        level.barrels.speedMin = round2(approach(tuning.speedMin, speedMinLimit, cleared))
        level.barrels.speedMax = round2(approach(tuning.speedMax, speedMaxLimit, cleared))
        level.barrels.spawnIntervalMs = approach(tuning.spawnIntervalMs, spawnIntervalLimitMs, cleared).rounded()
        level.barrels.maxActive = min(maxActiveCap, (tuning.maxActive ?? 6) + cleared / 2)
        var route = base.barrels.route ?? BarrelRoute()
        route.directThrowChance = round2(approach(tuning.route?.directThrowChance ?? 0, directThrowChanceLimit, cleared))
        level.barrels.route = route
        level.rescue.isFinalLevel = false
        return level
    }
}
