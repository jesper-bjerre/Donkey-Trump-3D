import Foundation

/// One clock epoch shared by the render loop and all producer threads.
final class GameplayClock {
    private let clock = ContinuousClock()
    private let origin: ContinuousClock.Instant
    init() { origin = clock.now }
    func now() -> Int64 {
        let duration = origin.duration(to: clock.now).components
        let (seconds, overflow) = duration.seconds.multipliedReportingOverflow(by: ActiveDuration.second)
        guard !overflow, let value = ActiveDuration.add(seconds, duration.attoseconds / 1_000_000_000) else { return Int64.max }
        return value
    }
}

/// This is the production clock/input adapter. Its caller supplies monotonic stamps;
/// the same adapter can be driven without SceneKit. Only drain is render-owned.
final class GameplayTimeline<Command> {
    private enum Change {
        case command(Command, abandon: Bool)
        case touch(InputState)
        case controller(InputState)
    }
    private struct Event { let stamp: Int64; let sequence: UInt64; let change: Change }
    private let lock = NSLock()
    private var incoming: [Event] = []
    private var sequence: UInt64 = 0
    private var lastTouch: InputState?
    private var lastController: InputState?
    private var pending: [Event] = []
    private var cursor: Int64?
    private var anchor: Int64 = 0
    private var tick: Int64 = 1
    private var touch = InputState()
    private var controller = InputState()
    private var pressEdges = 0
    private(set) var lastSliceCount = 0

    func enqueue(_ command: Command, at stamp: Int64, abandon: Bool = false) { enqueue(.command(command, abandon: abandon), at: stamp) }
    func enqueueTouch(_ state: InputState, at stamp: Int64) { enqueue(.touch(state), at: stamp) }
    func enqueueController(_ state: InputState, at stamp: Int64) { enqueue(.controller(state), at: stamp) }
    private func enqueue(_ change: Change, at stamp: Int64) {
        lock.lock(); defer { lock.unlock() }
        guard stamp >= 0, sequence < UInt64.max else { return }
        switch change {
        case .touch(let state):
            guard state != lastTouch else { return }; lastTouch = state
        case .controller(let state):
            guard state != lastController else { return }; lastController = state
        default: break
        }
        sequence += 1
        incoming.append(Event(stamp: stamp, sequence: sequence, change: change))
    }

    private func rebase(_ stamp: Int64) { cursor = stamp; anchor = stamp; tick = 1 }
    private var nextBoundary: Int64 {
        let whole = tick / 120
        let remainder = tick % 120
        return ActiveDuration.add(anchor, whole * ActiveDuration.second + remainder * ActiveDuration.second / 120) ?? Int64.max
    }

    private func apply(_ event: Event, command: (Command) -> Void) {
        switch event.change {
        case .command(let value, _): command(value)
        case .touch(var value):
            if value.jumpPressed || value.jumpHeld && !touch.jumpHeld { pressEdges += 1 }
            value.jumpPressed = false; touch = value
        case .controller(var value):
            if value.jumpPressed || value.jumpHeld && !controller.jumpHeld { pressEdges += 1 }
            value.jumpPressed = false; controller = value
        }
    }

    func drain(to now: Int64, advancing: () -> Bool = { true }, command: (Command) -> Void, slice: (Int64, InputState) -> Bool) {
        lock.lock(); pending += incoming; incoming.removeAll(keepingCapacity: true); lock.unlock()
        pending.sort { $0.stamp == $1.stamp ? $0.sequence < $1.sequence : $0.stamp < $1.stamp }
        if cursor == nil { rebase(now) }
        guard let initial = cursor, now >= initial else { return }
        lastSliceCount = 0
        var index = 0
        // Explicit navigation may abandon old debt; ordinary pause never does.
        if let abandon = pending.first(where: { event in
            if case .command(_, true) = event.change { return event.stamp <= now }; return false
        }) {
            while index < pending.count && pending[index].stamp <= abandon.stamp {
                apply(pending[index], command: command); index += 1
            }
            pressEdges = 0
            rebase(max(initial, abandon.stamp))
        }
        while let current = cursor, current <= now {
            while index < pending.count && pending[index].stamp <= current {
                apply(pending[index], command: command); index += 1
                rebase(current)
            }
            guard current < now else { break }
            let eventAt = index < pending.count ? pending[index].stamp : Int64.max
            if !advancing() {
                pressEdges = 0
                rebase(min(now, eventAt))
                continue
            }
            guard lastSliceCount < 32 else { break }
            let boundary = nextBoundary
            let end = min(boundary, eventAt)
            guard end <= now, end > current else { break }
            let input = InputState(left: touch.left || controller.left, right: touch.right || controller.right,
                up: touch.up || controller.up, down: touch.down || controller.down,
                jumpHeld: touch.jumpHeld || controller.jumpHeld, jumpPressed: pressEdges > 0)
            if pressEdges > 0 { pressEdges -= 1 }
            lastSliceCount += 1
            let retired = slice(end - current, input)
            cursor = end
            if end == boundary { tick += 1 } else { rebase(end) }
            if retired {
                // Retire this attempt's later intervals, but never lose app activity/navigation.
                while index < pending.count && pending[index].stamp <= now {
                    apply(pending[index], command: command); index += 1
                }
                pressEdges = 0; rebase(now)
                break
            }
        }
        if index > 0 { pending.removeFirst(index) }
    }
}
