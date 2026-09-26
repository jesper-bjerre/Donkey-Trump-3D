import Foundation

enum IntroSound: String, CaseIterable {
    case step = "introStep"
    case climb = "introClimb"
    case drop = "introDrop"
    case sign = "introSign"
    case stamp = "introStamp"
    case creak = "introCreak"
    case impact = "introImpact"
    case ready = "introReady"
}

struct IntroSoundCue: Equatable {
    let time: Double
    let sound: IntroSound
    var rate: Float = 1
}

/// One-shot cues on the same clock as the cutscene. No delayed callbacks survive
/// a skip or restart, and crossing a frame boundary cannot lose or repeat a cue.
struct IntroSoundtrack {
    let cues: [IntroSoundCue]

    init(timeline: IntroTimeline) {
        var result: [IntroSoundCue] = []
        var start = 0.0
        var foot = 0
        for segment in timeline.path {
            switch segment.action {
            case .walk, .climb:
                let climbing = segment.action == .climb
                let interval = climbing ? 0.22 : 0.18
                var beat = 0
                for offset in stride(from: 0.06, to: segment.duration, by: interval) {
                    let rate: Float
                    if climbing {
                        // A rising ladder arpeggio, reversed on the way back down.
                        let notes: [Float] = [1, 1.125, 1.25, 1.5]
                        let index = beat % notes.count
                        rate = notes[segment.to.y < segment.from.y ? index : notes.count - 1 - index]
                    } else {
                        rate = foot.isMultiple(of: 2) ? 0.9 : 1.05
                        foot += 1
                    }
                    result.append(IntroSoundCue(time: start + offset, sound: climbing ? .climb : .step, rate: rate))
                    beat += 1
                }
            case .drop:
                result.append(IntroSoundCue(time: start, sound: .drop))
            }
            start += segment.duration
        }

        result.append(IntroSoundCue(time: timeline.pathEnd, sound: .sign))
        // The signature finishes at 80% of the signing phase (see HUD progress).
        result.append(IntroSoundCue(time: timeline.pathEnd + IntroTiming.sign * 0.8, sound: .stamp))
        for girder in 0..<timeline.girderCount {
            let start = timeline.signEnd + Double(girder) * IntroTiming.tiltPerGirder
            result.append(IntroSoundCue(time: start, sound: .creak))
            result.append(IntroSoundCue(time: start + IntroTiming.tiltPerGirder, sound: .impact))
        }
        result.append(IntroSoundCue(time: timeline.tiltEnd + 0.15, sound: .ready))
        cues = result.sorted { $0.time < $1.time }
    }

    /// An exclusive lower bound lets adjacent frames share their boundary safely.
    func cues(after previousTime: Double, through time: Double) -> [IntroSoundCue] {
        guard time > previousTime else { return [] }
        return cues.filter { $0.time > previousTime && $0.time <= time }
    }
}
