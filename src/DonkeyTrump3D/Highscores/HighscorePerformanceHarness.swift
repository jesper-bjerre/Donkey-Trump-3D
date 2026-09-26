#if DEBUG
import SwiftUI
import QuartzCore

/// Local integration instrumentation. Never compiled into Release or enabled by ordinary fixtures.
actor HighscorePerformanceService: HighscoreService {
    enum Mode { case real, normal, delayed, unavailable }
    let base: any HighscoreService
    var mode: Mode = .real
    init(base: any HighscoreService) { self.base = base }
    func set(_ mode: Mode) { self.mode = mode }
    func read() async throws -> HighscoreSnapshot {
        switch mode {
        case .real: return try await base.read()
        case .normal: return HighscoreFixtureService.prepared(count: 100)
        case .delayed: try await Task.sleep(for: .seconds(60)); throw HighscoreServiceError.unavailable
        case .unavailable: throw HighscoreServiceError.unavailable
        }
    }
    func submit(_ submission: HighscoreSubmission) async throws -> HighscoreSnapshot { try await base.submit(submission) }
}

@MainActor @Observable final class HighscorePerformanceHarness {
    static let shared = HighscorePerformanceHarness()
    var service: HighscorePerformanceService?
    var result = "pending"
    var activeKind: String?
    var visibleAt: Double?
    var startedAt = 0.0
    private var hasRun = false
    var isEnabled: Bool {
        guard ProcessInfo.processInfo.arguments.contains("-highscorePerformance") || ProcessInfo.processInfo.arguments.contains("-highscoreDeadlineProbe"),
              case .integration = HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) else { return false }
        return true
    }
    func begin(_ kind: String) { visibleAt = nil; activeKind = kind; startedAt = CACurrentMediaTime() }
    func visible(_ kind: String) {
        if activeKind == kind && visibleAt == nil { visibleAt = CACurrentMediaTime(); activeKind = nil }
    }
    private func wait(_ predicate: () -> Bool, seconds: Double = 9) async throws {
        let deadline = CACurrentMediaTime() + seconds
        while !predicate() {
            if CACurrentMediaTime() > deadline { throw Failure.timeout }
            try await Task.sleep(for: .milliseconds(2))
        }
    }
    private func elapsed() async throws -> Double {
        try await wait { visibleAt != nil }
        return (visibleAt! - startedAt) * 1000
    }
    enum Failure: Error { case timeout, unexpectedState }

    func run(_ model: GameModel) async {
        guard isEnabled, !hasRun, let service else { return }; hasRun = true
        do {
            if ProcessInfo.processInfo.arguments.contains("-highscoreDeadlineProbe") {
                begin("failure"); model.highscores.openTitle()
                let duration = try await elapsed()
                result = String(decoding: try JSONSerialization.data(withJSONObject: ["streamFailureVisibleMs": duration]), as: UTF8.self)
                return
            }
            var baseline: [Double] = [], starts: [Double] = [], reads: [Double] = [], posts: [Double] = []
            let modes: [HighscorePerformanceService.Mode] = [.normal, .delayed, .unavailable]
            for i in 0..<100 {
                for measured in [false, true] {
                    await service.set(modes[i % modes.count])
                    if i % 2 == 0 {
                        model.send(.toTitle); try await wait { model.hud.phase == .title }
                        if measured { model.highscores.openTitle() }
                    } else {
                        let run = CompletedRun(id: UUID(), score: 0, levelReached: 1)
                        model.engine.send(.highscoreFixtureGameOver(run))
                        try await wait { model.hud.completedRun?.id == run.id }
                        if !measured { model.highscores.invalidate() }
                    }
                    try await Task.sleep(for: .milliseconds(50))
                    begin("game"); model.send(i % 2 == 0 ? .startGame : .restart)
                    let duration = try await elapsed()
                    if measured { starts.append(duration) } else { baseline.append(duration) }
                }
            }
            await service.set(.real)
            // Warm storage/API and URLSession before acceptance samples.
            _ = try await service.read()
            for i in 0..<100 {
                model.send(.toTitle); try await wait { model.hud.phase == .title }
                begin("list"); model.highscores.openTitle(); reads.append(try await elapsed())
                let run = CompletedRun(id: UUID(), score: 2_000_000_000 + i * 100, levelReached: 1)
                model.engine.send(.highscoreFixtureGameOver(run))
                try await wait { if case .enteringName(let current, _) = model.highscores.state { current.id == run.id } else { false } }
                begin("list"); model.highscores.submit(name: "Local performance"); posts.append(try await elapsed())
                guard case .browsing(let b) = model.highscores.state, b.anchor == .highlight(run.id) else { throw Failure.unexpectedState }
                try await Task.sleep(for: .milliseconds(510)) // Stay inside unchanged production POST limits.
            }
            await service.set(.delayed)
            model.send(.toTitle); try await wait { model.hud.phase == .title }
            begin("failure"); model.highscores.openTitle(); let deadline = try await elapsed()
            let payload: [String: Any] = ["baselineMs": baseline, "startRestartMs": starts,
                "readVisibleMs": reads, "postVisibleMs": posts, "hungFailureVisibleMs": deadline,
                "method": "Monotonic action-to-second-display-frame on mounted visible SwiftUI content; 50 starts/50 restarts, normal/delayed/unavailable services interleaved against paired baseline"]
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try data.write(to: directory.appendingPathComponent("highscore-performance.json"), options: .atomic)
            result = String(decoding: data, as: UTF8.self)
        } catch { result = "failed: \(error)" }
    }
}

/// Marks readiness only after content has a window, a real layout and two display refreshes.
struct HighscoreRenderProbe: UIViewRepresentable {
    let kind: String
    let marker: String
    func makeUIView(context: Context) -> Probe { Probe() }
    func updateUIView(_ view: Probe, context: Context) { view.arm(kind: kind, marker: marker) }
    @MainActor final class Probe: UIView {
        private var marker: String?
        private var kind = ""
        private var ticks = 0
        private var link: CADisplayLink?
        func arm(kind: String, marker: String) {
            guard HighscorePerformanceHarness.shared.isEnabled, self.marker != marker else { return }
            self.marker = marker; self.kind = kind; ticks = 0; link?.invalidate()
            let link = CADisplayLink(target: self, selector: #selector(tick)); self.link = link
            link.add(to: .main, forMode: .common)
        }
        @objc private func tick() {
            guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
            ticks += 1
            if ticks >= 2 { link?.invalidate(); link = nil; HighscorePerformanceHarness.shared.visible(kind) }
        }
        override func didMoveToWindow() { if window == nil { link?.invalidate(); link = nil } }
    }
}
#endif
