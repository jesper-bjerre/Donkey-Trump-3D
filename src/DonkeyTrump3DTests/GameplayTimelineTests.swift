import Testing
@testable import DonkeyTrump3D

@Suite("Production gameplay timeline")
struct GameplayTimelineTests {
    @Test func firstSampleDoesNotInventTimeAndBudgetRetainsDebt() {
        let t = GameplayTimeline<Int>()
        var total: Int64 = 0
        t.drain(to: 1_000_000_000, command: { _ in }, slice: { ns, _ in total += ns; return false })
        #expect(total == 0)
        t.drain(to: 2_000_000_000, command: { _ in }, slice: { ns, _ in total += ns; return false })
        #expect(t.lastSliceCount == 32)
        #expect(total < 1_000_000_000)
        for _ in 0..<4 { t.drain(to: 2_000_000_000, command: { _ in }, slice: { ns, _ in total += ns; return false }) }
        #expect(total == 1_000_000_000)
    }

    @Test func integralBoundariesAtEverySupportedRate() {
        for hz in [30, 60, 120] {
            let t = GameplayTimeline<Int>()
            var total: Int64 = 0
            t.drain(to: 0, command: { _ in }, slice: { _, _ in false })
            for n in 1...(180 * hz) {
                t.drain(to: Int64(n) * 1_000_000_000 / Int64(hz), command: { _ in },
                    slice: { ns, _ in total += ns; return false })
            }
            #expect(total == 180_000_000_000)
        }
    }
}

extension GameplayTimelineTests {
    @Test func inactiveMinuteAndFractionalCommandsAreExcluded() {
        let t = GameplayTimeline<Bool>()
        var active = true, total: Int64 = 0
        t.drain(to: 0, command: { active = $0 }, slice: { _, _ in false })
        t.enqueue(false, at: 60_000_000_001)
        t.enqueue(true, at: 120_000_000_001)
        for n in 1...10_800 {
            t.drain(to: Int64(n) * 1_000_000_000 / 60, advancing: { active }, command: { active = $0 },
                    slice: { ns, _ in total += ns; return false })
        }
        #expect(total == 120_000_000_000)
    }
    @Test func inputCannotMoveBackwardsAndPressIsConsumedOnce() {
        let t = GameplayTimeline<Int>()
        var presses = 0, earlyInput = false, total: Int64 = 0
        t.drain(to: 0, command: { _ in }, slice: { _, _ in false })
        t.enqueueTouch(.init(right: true, jumpHeld: true), at: 1_000_000_000)
        for _ in 0..<9 {
            t.drain(to: 2_000_000_000, command: { _ in }, slice: { ns, input in
                if total < 1_000_000_000 && input.right { earlyInput = true }
                if input.jumpPressed { presses += 1 }
                total += ns; return false
            })
        }
        #expect(!earlyInput); #expect(presses == 1); #expect(total == 2_000_000_000)
    }
    @Test func terminalRetirementStillDeliversPendingLifecycle() {
        let t = GameplayTimeline<Int>(); var commands: [Int] = [], slices = 0
        t.drain(to: 0, command: { _ in }, slice: { _, _ in false })
        t.enqueue(42, at: 900_000_000)
        t.drain(to: 1_000_000_000, command: { commands.append($0) }, slice: { _, _ in slices += 1; return true })
        #expect(slices == 1); #expect(commands == [42])
    }
}
