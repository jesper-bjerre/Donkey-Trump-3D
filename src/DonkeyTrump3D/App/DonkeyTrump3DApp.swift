import SceneKit
import SwiftUI

@main
struct DonkeyTrump3DApp: App {
    @State private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            AudioSystem.shared.setMenuMusicActive(phase == .active)
        }
        .onChange(of: scenePhase) { old, phase in
            // Only pause when leaving an active session, not during the launch transition.
            if old == .active && phase != .active { model.engine.send(.pause) }
            if phase == .background { model.highscores.background() }
        }
    }
}

@MainActor @Observable
final class GameModel {
    var hud = HUDState()
    var showHowTo = false
    private(set) var isSceneReady = false
    var muted = AudioSystem.shared.muted {
        didSet { AudioSystem.shared.muted = muted }
    }
    var haptics = Haptics.enabled {
        didSet { Haptics.enabled = haptics }
    }
    let engine: GameEngine
    let highscores: HighscoreCoordinator

    init(service: (any HighscoreService)? = nil) {
        let selected: any HighscoreService
        let options = LaunchOptions.current
        if let service { selected = service }
        else if options.autopilot || options.autostart || options.iconShot || options.introAt != nil {
            selected = UnavailableHighscoreService()
        } else {
            #if DEBUG
            if let mode = HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) {
                switch mode {
                case .fixture(let name): selected = HighscoreFixtureService(name, recordCounters: true)
                case .integration(let origin):
                    if let configuration = try? HighscoreConfiguration(localOrigin: origin) { selected = URLSessionHighscoreService(configuration: configuration) }
                    else { selected = UnavailableHighscoreService() }
                case .unavailable: selected = UnavailableHighscoreService()
                }
            } else if let configuration = HighscoreConfiguration.bundled() { selected = URLSessionHighscoreService(configuration: configuration) }
            else { selected = UnavailableHighscoreService() }
            #else
            if let configuration = HighscoreConfiguration.bundled() { selected = URLSessionHighscoreService(configuration: configuration) }
            else { selected = UnavailableHighscoreService() }
            #endif
        }
        #if DEBUG
        if HighscorePerformanceHarness.shared.isEnabled {
            let wrapped = HighscorePerformanceService(base: selected)
            HighscorePerformanceHarness.shared.service = wrapped
            highscores = HighscoreCoordinator(service: wrapped)
        } else { highscores = HighscoreCoordinator(service: selected) }
        #else
        highscores = HighscoreCoordinator(service: selected)
        #endif
        engine = GameEngine()
        engine.firstFrameSink = { [weak self] in
            MainActor.assumeIsolated { self?.isSceneReady = true }
        }
        engine.hudSink = { [weak self] snapshot in
            MainActor.assumeIsolated { self?.receive(snapshot) }
        }
    }

    func send(_ command: EngineCommand) {
        switch command {
        case .startGame, .restart, .toTitle: highscores.invalidate()
        default: break
        }
        engine.send(command)
    }

    private func receive(_ snapshot: HUDState) {
        if hud.runID != snapshot.runID || hud.phase == .gameOver && snapshot.phase != .gameOver { highscores.invalidate() }
        hud = snapshot
        if snapshot.phase == .gameOver, let run = snapshot.completedRun { highscores.complete(run) }
    }
}

/// Hosts the SceneKit view; the engine renders and simulates on SceneKit's loop.
struct GameSceneView: UIViewRepresentable {
    let engine: GameEngine

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero, options: [SCNView.Option.preferredRenderingAPI.rawValue: NSNumber(value: SCNRenderingAPI.metal.rawValue)])
        view.scene = engine.scene
        view.pointOfView = engine.cameraNode
        view.delegate = engine
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 120
        view.rendersContinuously = true
        view.isPlaying = true
        view.loops = true
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}
}

struct TouchControlsLayer: UIViewRepresentable {
    let hub: InputHub

    func makeUIView(context: Context) -> TouchControlsView {
        let view = TouchControlsView()
        view.hub = hub
        return view
    }

    func updateUIView(_ view: TouchControlsView, context: Context) {}

    static func dismantleUIView(_ view: TouchControlsView, coordinator: ()) {
        view.hub?.clear()
    }
}
