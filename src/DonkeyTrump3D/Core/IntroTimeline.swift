import Foundation

// Choreography for the opening cutscene, built from the level's own geometry: the
// girders start flat, Donkey Trump carries Motzfeldt up the ladders to the top,
// leaves her there, returns to his spot and signs an executive order that tilts
// every girder into its slope. Pure data, so the whole sequence is testable.

enum IntroTiming {
    static let walkSpeed = 420.0 // level px/s
    static let climbSpeed = 200.0
    static let enterFromX = 880.0 // off-stage right
    static let dropPause = 0.8
    static let sign = 2.4
    static let tiltPerGirder = 0.36
    static let card = 2.4
}

enum IntroPhase: Equatable {
    case path, sign, tilt, card, done
}

struct LadderLink: Equatable {
    var ladder: LevelLadder
    var bottom: Int
    var top: Int
}

struct IntroSegment: Equatable {
    enum Action: Equatable { case walk, climb, drop }
    var from: LevelPoint
    var to: LevelPoint
    var action: Action
    var duration: Double
    var carrying: Bool
}

struct IntroPose: Equatable {
    var x: Double
    var y: Double
    var action: IntroSegment.Action?
    var carrying: Bool
    var facingLeft: Bool
}

struct IntroTimeline {
    let path: [IntroSegment]
    let pathEnd: Double
    let signEnd: Double
    let tiltEnd: Double
    let end: Double
    let girderCount: Int

    /// Which floors (girder indexes) each ladder connects, from the final geometry.
    static func ladderLinks(_ level: Level) -> [LadderLink] {
        let segments = level.girders.map(Segment.init)
        func floorAt(_ x: Double, _ y: Double) -> Int {
            segments.firstIndex { $0.contains(x) && abs($0.y(at: x) - y) < 0.6 } ?? -1
        }
        return level.ladders.map { l in
            LadderLink(ladder: l, bottom: floorAt(l.snapX, l.y + l.height), top: floorAt(l.snapX, l.y))
        }
    }

    /// A ladder's ends follow the girders while they tilt.
    static func ladder(_ link: LadderLink, on segments: [Segment]) -> LevelLadder {
        var l = link.ladder
        guard segments.indices.contains(link.top), segments.indices.contains(link.bottom) else { return l }
        let top = segments[link.top].y(at: l.snapX)
        let bottom = segments[link.bottom].y(at: l.snapX)
        l.y = top
        l.height = bottom - top
        return l
    }

    init(level: Level) {
        let segments = level.girders.map(Segment.init)
        let floors = segments.map(\.midY)
        let links = IntroTimeline.ladderLinks(level)
        let top = segments.count - 1
        let bossFloor = top - 1
        var result: [IntroSegment] = []
        var at = LevelPoint(x: IntroTiming.enterFromX, y: floors[0])

        func walk(to x: Double, carrying: Bool) {
            let to = LevelPoint(x: x, y: at.y)
            if to.x != at.x {
                result.append(IntroSegment(from: at, to: to, action: .walk, duration: abs(to.x - at.x) / IntroTiming.walkSpeed, carrying: carrying))
            }
            at = to
        }
        func climb(to y: Double, carrying: Bool) {
            let to = LevelPoint(x: at.x, y: y)
            result.append(IntroSegment(from: at, to: to, action: .climb, duration: abs(to.y - at.y) / IntroTiming.climbSpeed, carrying: carrying))
            at = to
        }

        var lastLink: LadderLink?
        for floor in 0..<top {
            guard let link = links.first(where: { $0.bottom == floor && $0.top == floor + 1 }) else { continue }
            walk(to: link.ladder.snapX, carrying: true)
            climb(to: floors[floor + 1], carrying: true)
            lastLink = link
        }
        walk(to: level.rescue.x + level.rescue.width / 2, carrying: true)
        result.append(IntroSegment(from: at, to: at, action: .drop, duration: IntroTiming.dropPause, carrying: false))
        if let lastLink {
            walk(to: lastLink.ladder.snapX, carrying: false)
            climb(to: floors[bossFloor], carrying: false)
        }
        walk(to: level.boss.x, carrying: false)

        path = result
        girderCount = segments.count
        pathEnd = result.reduce(0) { $0 + $1.duration }
        signEnd = pathEnd + IntroTiming.sign
        tiltEnd = signEnd + Double(segments.count) * IntroTiming.tiltPerGirder
        end = tiltEnd + IntroTiming.card
    }

    func pose(at time: Double) -> IntroPose {
        var remaining = max(0, time)
        for seg in path {
            if remaining <= seg.duration {
                let t = seg.duration == 0 ? 1 : remaining / seg.duration
                return IntroPose(
                    x: seg.from.x + (seg.to.x - seg.from.x) * t,
                    y: seg.from.y + (seg.to.y - seg.from.y) * t,
                    action: seg.action,
                    carrying: seg.carrying,
                    facingLeft: seg.to.x < seg.from.x
                )
            }
            remaining -= seg.duration
        }
        let last = path.last?.to ?? LevelPoint(x: 0, y: 0)
        return IntroPose(x: last.x, y: last.y, action: nil, carrying: false, facingLeft: true)
    }

    /// Tilt progress per girder (0 flat ... 1 sloped). Girders tilt one after another
    /// from the top floor down, like a wave spreading from the signed order.
    func tilts(at time: Double) -> [Double] {
        (0..<girderCount).map { index in
            let order = Double(girderCount - 1 - index)
            let start = signEnd + order * IntroTiming.tiltPerGirder
            return min(1, max(0, (time - start) / IntroTiming.tiltPerGirder))
        }
    }

    func phase(at time: Double) -> IntroPhase {
        if time < pathEnd { return .path }
        if time < signEnd { return .sign }
        if time < tiltEnd { return .tilt }
        if time < end { return .card }
        return .done
    }
}
