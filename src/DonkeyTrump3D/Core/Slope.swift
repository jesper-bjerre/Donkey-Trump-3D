import Foundation

/// A girder surface, always stored left-to-right.
struct Segment: Equatable {
    var x1: Double
    var y1: Double
    var x2: Double
    var y2: Double

    init(x1: Double, y1: Double, x2: Double, y2: Double) {
        if x1 <= x2 {
            self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
        } else {
            self.x1 = x2; self.y1 = y2; self.x2 = x1; self.y2 = y1
        }
    }

    init(_ girder: LevelGirder) {
        self.init(x1: girder.x1, y1: girder.y1, x2: girder.x2, y2: girder.y2)
        if girder.collisionMode == "flat-body" {
            let top = min(y1, y2)
            y1 = top; y2 = top
        }
    }

    func contains(_ x: Double) -> Bool { x >= x1 && x <= x2 }

    func y(at x: Double) -> Double { y1 + (x - x1) / (x2 - x1) * (y2 - y1) }

    /// Downhill horizontal direction: -1 left, 1 right, 0 flat.
    var downhill: Double { y2 > y1 ? 1 : (y2 < y1 ? -1 : 0) }

    var midY: Double { (y1 + y2) / 2 }

    /// Interpolates from flat (tilt 0) to the real slope (tilt 1), around the midpoint.
    func tilted(_ tilt: Double) -> Segment {
        Segment(x1: x1, y1: midY + (y1 - midY) * tilt, x2: x2, y2: midY + (y2 - midY) * tilt)
    }
}

struct Bounds: Equatable {
    var left: Double
    var right: Double
    var top: Double
    var bottom: Double

    var centerX: Double { (left + right) / 2 }

    func overlaps(_ o: Bounds) -> Bool {
        right > o.left && left < o.right && bottom > o.top && top < o.bottom
    }

    func inset(_ d: Double) -> Bounds {
        Bounds(left: left + d, right: right - d, top: top + d, bottom: bottom - d)
    }
}

struct SlopeContact {
    var bottom: Double
    var grounded: Bool
    var segmentIndex: Int?
}

// Line-segment slope math: bodies are snapped onto girders each step.
enum Slope {
    /// How far above the surface feet may be and still count as touching it.
    static let abovePx = 2.0
    /// How far below the surface feet may sink in one step and still be caught.
    static let belowPx = 12.0

    static func support(x: Double, footY: Double, segments: [Segment]) -> (index: Int, surfaceY: Double)? {
        var best: (Int, Double)?
        var bestDistance = Double.infinity
        for (i, s) in segments.enumerated() where s.contains(x) {
            let surface = s.y(at: x)
            let sink = footY - surface
            if sink < -abovePx || sink > belowPx { continue }
            if abs(sink) < bestDistance {
                best = (i, surface)
                bestDistance = abs(sink)
            }
        }
        return best
    }

    /// Rising bodies are never snapped, so jumps are not cut short by their own girder.
    static func resolve(x: Double, bottom: Double, velocityY: Double, segments: [Segment]) -> SlopeContact {
        if velocityY < 0 { return SlopeContact(bottom: bottom, grounded: false, segmentIndex: nil) }
        guard let s = support(x: x, footY: bottom, segments: segments) else {
            return SlopeContact(bottom: bottom, grounded: false, segmentIndex: nil)
        }
        return SlopeContact(bottom: s.surfaceY, grounded: true, segmentIndex: s.index)
    }

    /// Which girder a point stands on (closest surface at or below it), for floor lookups.
    static func floorIndex(x: Double, footY: Double, segments: [Segment]) -> Int? {
        var best: Int?
        var bestDistance = Double.infinity
        for (i, s) in segments.enumerated() where s.contains(x) {
            let d = s.y(at: x) - footY
            if d >= -belowPx && d < bestDistance {
                best = i
                bestDistance = d
            }
        }
        return best
    }
}
