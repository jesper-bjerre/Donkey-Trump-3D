import SceneKit
import UIKit

struct HUDState: Equatable {
    var phase: GamePhase = .title
    var score = 0
    var best = 0
    var lives = ScoreRules.startingLives
    var level = 1
    var levelName = ""
    var introPhase: IntroPhase = .path
    /// 0...1 progress of the executive-order signature.
    var signProgress = 0.0
    var ladderHint = false
    var runID: UUID?
    var completedRun: CompletedRun?
}

enum EngineCommand {
    case startGame, skipIntro, pause, resume, restart, toTitle
    #if DEBUG
    case highscoreFixtureGameOver(CompletedRun)
    #endif
}

struct LaunchOptions {
    var autopilot = false
    var autostart = false
    /// Debug: a UI-free close-up of the boss, used to render the app icon.
    var iconShot = false
    var introAt: Double?
    var phaseOverride: String?

    static let current: LaunchOptions = {
        let args = ProcessInfo.processInfo.arguments
        var o = LaunchOptions()
        o.autopilot = args.contains("-autopilot")
        o.autostart = args.contains("-autostart")
        o.iconShot = args.contains("-iconShot")
        if let i = args.firstIndex(of: "-introAt"), i + 1 < args.count { o.introAt = Double(args[i + 1]) }
        return o
    }()
}

/// Runs the game on SceneKit's render loop: a fixed-step simulation, the 3D scene
/// sync, cinematic cameras, the intro cutscene, effects, sound and haptics.
final class GameEngine: NSObject, SCNSceneRendererDelegate {
    static let step = 1.0 / 120.0

    let scene = SCNScene()
    let inputHub = InputHub()
    var hudSink: ((HUDState) -> Void)?

    private let session: GameSession
    private let options = LaunchOptions.current

    // Scene graph
    let cameraNode = SCNNode()
    private let levelRoot = SCNNode()
    private let fxRoot = SCNNode()
    private let lokke = LokkeCharacter()
    private let boss = BossCharacter()
    private let motz = MotzfeldtCharacter()
    private var girderNodes: [SCNNode] = []
    private var ladderNodes: [SCNNode] = []
    private var barrelNodes: [Int: SCNNode] = [:]
    private let helpBubble = Effects.bubble("HELP!")
    private let savedBubble = Effects.bubble("SAVED!", fill: UIColor(hex: 0x7dffb0))
    private let gloatBubble = Effects.bubble("SAD!", fill: UIColor(hex: 0xffffff))
    private var aurora: [SCNMaterial] = []
    private var beacons: [SCNNode] = []
    private var craneJib = SCNNode()
    private var sign = SCNNode()
    private let keyLight = SCNNode()
    private let rescueLight = SCNNode()
    private var builtLevelKey = ""
    private var themeIndex = -1

    // Loop state
    private let commandLock = NSLock()
    private var commands: [EngineCommand] = []
    private var lastTime: TimeInterval?
    private var accumulator = 0.0
    private var clock = 0.0
    private var lastJumpPresses = 0
    private var lastControllerJump = false
    private var autopilot = Autopilot()
    private var titleDemo = Autopilot()

    // Intro
    private var intro: IntroTimeline?
    private var introSoundtrack: IntroSoundtrack?
    private var introTime = 0.0
    private var introLinks: [LadderLink] = []
    private var lastTilts: [Double] = []

    // Presentation
    private var camPos = SIMD3<Float>(0, 8, 30)
    private var camTarget = SIMD3<Float>(0, 7, 0)
    private var shake: Float = 0
    private var bossThrowTimer = 0.0
    private var bossMoodTimer = 0.0
    private var lastHUD: HUDState?
    private let reducedMotion = UIAccessibility.isReduceMotionEnabled

    override init() {
        let defaults: UserDefaults
        #if DEBUG
        if HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) != nil {
            defaults = UserDefaults(suiteName: "com.hyldenbrandt.donkeytrump3d.highscore-fixtures")!
        } else { defaults = .standard }
        #else
        defaults = .standard
        #endif
        session = GameSession(best: defaults.integer(forKey: "best"), saveBest: { defaults.set($0, forKey: "best") })
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-highscoreCompletedRun"), let mode = HighscoreFixtureLaunch.parse(arguments) {
            let name: String
            if case .fixture(let fixture) = mode { name = fixture } else { name = "empty" }
            let id: UUID
            if let index = arguments.firstIndex(of: "-highscoreRunID"), index + 1 < arguments.count,
               let supplied = UUID(uuidString: arguments[index + 1]), supplied != HighscoreRules.zeroID { id = supplied }
            else { id = UUID() }
            session.completeForHighscoreFixture(HighscoreFixtureLaunch.run(for: name, id: id))
        }
        #endif
        super.init()
        buildScene()
        buildLevel(session.level, tilt: 1)
        if options.autostart {
            session.startNewGame()
            handle(session.beginPlay())
        } else if let at = options.introAt {
            session.startNewGame()
            startIntro(at: at)
        }
    }

    func send(_ command: EngineCommand) {
        commandLock.lock()
        commands.append(command)
        commandLock.unlock()
    }

    // MARK: - Scene setup

    private func buildScene() {
        let camera = SCNCamera()
        camera.fieldOfView = 40
        camera.zNear = 0.1
        camera.zFar = 600
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.1
        camera.bloomIntensity = 1.1
        camera.bloomThreshold = 0.9
        camera.bloomBlurRadius = 12
        camera.vignettingIntensity = 0.55
        camera.vignettingPower = 0.9
        camera.colorFringeStrength = 0.35
        camera.colorFringeIntensity = 0.5
        camera.saturation = 1.12
        camera.contrast = 0.1
        camera.screenSpaceAmbientOcclusionIntensity = 0.8
        camera.screenSpaceAmbientOcclusionRadius = 0.5
        camera.screenSpaceAmbientOcclusionNormalThreshold = 0.3
        camera.screenSpaceAmbientOcclusionDepthThreshold = 0.2
        camera.focusDistance = 6
        camera.fStop = 2
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(camPos.x, camPos.y, camPos.z)
        scene.rootNode.addChildNode(cameraNode)

        // Moonlit key light with soft shadows.
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1150
        key.color = UIColor(hex: 0xdfe6ff)
        key.castsShadow = true
        key.shadowMode = .deferred
        key.shadowMapSize = CGSize(width: 2048, height: 2048)
        key.shadowSampleCount = 12
        key.shadowRadius = 2.5
        key.shadowColor = UIColor(white: 0, alpha: 0.62)
        key.automaticallyAdjustsShadowProjection = false
        key.orthographicScale = 13
        key.zNear = 1
        key.zFar = 80
        key.shadowBias = 0.04
        keyLight.light = key
        keyLight.position = SCNVector3(9, 22, 24)
        keyLight.look(at: SCNVector3(0, 7, 0))
        scene.rootNode.addChildNode(keyLight)

        // Aurora-tinted rim light from behind.
        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 420
        rim.color = UIColor(hex: 0x6cffc8)
        let rimNode = SCNNode()
        rimNode.light = rim
        rimNode.position = SCNVector3(-6, 14, -20)
        rimNode.look(at: SCNVector3(0, 6, 0))
        scene.rootNode.addChildNode(rimNode)

        // Warm construction floodlights at the base.
        for x: Float in [-8, 8] {
            let spot = SCNLight()
            spot.type = .spot
            spot.intensity = 900
            spot.color = UIColor(hex: 0xffb35c)
            spot.spotInnerAngle = 20
            spot.spotOuterAngle = 55
            spot.attenuationStartDistance = 4
            spot.attenuationEndDistance = 26
            let n = SCNNode()
            n.light = spot
            n.position = SCNVector3(x, 0.4, 6)
            n.look(at: SCNVector3(x * 0.3, 9, 0))
            scene.rootNode.addChildNode(n)
            let lamp = SCNNode(geometry: SCNBox(width: 0.5, height: 0.35, length: 0.3, chamferRadius: 0.04))
            lamp.geometry?.materials = [Mat.glow(UIColor(hex: 0xffd08a), intensity: 3)]
            lamp.position = SCNVector3(x, 0.25, 6)
            scene.rootNode.addChildNode(lamp)
        }

        // Warm glow on the rescue platform.
        let rl = SCNLight()
        rl.type = .omni
        rl.intensity = 260
        rl.color = UIColor(hex: 0xffd2a0)
        rl.attenuationStartDistance = 1
        rl.attenuationEndDistance = 7
        rescueLight.light = rl
        scene.rootNode.addChildNode(rescueLight)

        let env = WorldBuilder.environment(into: scene.rootNode)
        aurora = env.aurora
        beacons = env.beacons
        craneJib = env.craneJib
        sign = env.sign

        let snow = SCNNode()
        snow.position = SCNVector3(0, 24, 2)
        snow.addParticleSystem(Effects.snow())
        scene.rootNode.addChildNode(snow)

        scene.rootNode.addChildNode(levelRoot)
        scene.rootNode.addChildNode(fxRoot)
        for c in [lokke.root, boss.root, motz.root] { scene.rootNode.addChildNode(c) }
        for b in [helpBubble, savedBubble, gloatBubble] {
            b.isHidden = true
            scene.rootNode.addChildNode(b)
        }
        scene.fogStartDistance = 70
        scene.fogEndDistance = 420
        scene.fogDensityExponent = 1.6
        scene.lightingEnvironment.intensity = 1.3
        applyTheme(0)
    }

    private func applyTheme(_ layout: Int) {
        guard layout != themeIndex else { return }
        themeIndex = layout
        let theme = Theme.forLayout(layout)
        scene.background.contents = Tex.sky(theme)
        scene.lightingEnvironment.contents = Tex.environment(theme)
        scene.fogColor = theme.skyHorizon.withAlphaComponent(1)
        WorldBuilder.setAurora(aurora, theme: theme)
    }

    /// Rebuilds girders and ladders for a level; `tilt` 0 lays every girder flat (intro).
    private func buildLevel(_ level: Level, tilt: Double) {
        applyTheme(level.layoutIndex)
        let key = level.id
        if key != builtLevelKey {
            builtLevelKey = key
            girderNodes.forEach { $0.removeFromParentNode() }
            girderNodes = level.girders.map { WorldBuilder.girder(Segment($0)) }
            girderNodes.forEach { levelRoot.addChildNode($0) }
            introLinks = IntroTimeline.ladderLinks(level)
            lastTilts = []
        }
        applyTilts(Array(repeating: tilt, count: level.girders.count), level: level)
        barrelNodes.values.forEach { $0.isHidden = true; $0.childNodes.first?.removeAllParticleSystems() }
    }

    private func applyTilts(_ tilts: [Double], level: Level) {
        guard tilts != lastTilts else { return }
        lastTilts = tilts
        let segments = zip(level.girders, tilts).map { Segment($0.0).tilted($0.1) }
        for (node, segment) in zip(girderNodes, segments) { WorldBuilder.place(node, on: segment) }
        ladderNodes.forEach { $0.removeFromParentNode() }
        ladderNodes = introLinks.map { WorldBuilder.ladder(IntroTimeline.ladder($0, on: segments)) }
        ladderNodes.forEach { levelRoot.addChildNode($0) }
    }

    // MARK: - Frame loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let dt = lastTime.map { min(max(time - $0, 0), 1.0 / 20) } ?? 1.0 / 60
        lastTime = time
        clock += dt

        let controller = ControllerInput.poll()
        processCommands(controller)

        switch session.phase {
        case .title:
            updateTitle(dt)
        case .intro:
            updateIntro(dt)
        default:
            updateGame(dt, controller: controller)
        }
        updateAmbience(dt)
        updateCamera(dt)
        publishHUD()
    }

    private func processCommands(_ controller: ControllerInput) {
        commandLock.lock()
        var pending = commands
        commands.removeAll()
        commandLock.unlock()

        if controller.pausePressed {
            switch session.phase {
            case .play: pending.append(.pause)
            case .paused: pending.append(.resume)
            case .intro: pending.append(.skipIntro)
            default: break
            }
        }
        if controller.confirmPressed {
            switch session.phase {
            case .title: pending.append(.startGame)
            case .intro: pending.append(.skipIntro)
            case .gameOver: pending.append(.restart)
            case .paused: pending.append(.resume)
            default: break
            }
        }

        for command in pending {
            switch command {
            #if DEBUG
            case .highscoreFixtureGameOver(let run):
                guard HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) != nil else { continue }
                intro = nil; introSoundtrack = nil; session.completeForHighscoreFixture(run)
            #endif
            case .startGame where session.phase == .title:
                session.startNewGame()
                startIntro()
            case .skipIntro where session.phase == .intro:
                finishIntro()
            case .pause where session.phase == .play:
                session.pause()
                AudioSystem.shared.pauseMusic()
            case .resume where session.phase == .paused:
                session.resume()
                inputHub.clear()
                AudioSystem.shared.resumeMusic()
            case .restart where [.paused, .gameOver].contains(session.phase):
                handle(session.restart())
            case .toTitle:
                AudioSystem.shared.stopMusic()
                AudioSystem.shared.stopIntro()
                intro = nil
                introSoundtrack = nil
                session.showTitle()
                buildLevel(session.level, tilt: 1)
            default:
                break
            }
        }
    }

    private func mergedInput(_ controller: ControllerInput) -> (InputState, Int) {
        let touch = inputHub.snapshot()
        var input = touch.state
        input.left = input.left || controller.state.left
        input.right = input.right || controller.state.right
        input.up = input.up || controller.state.up
        input.down = input.down || controller.state.down
        input.jumpHeld = input.jumpHeld || controller.state.jumpHeld
        var presses = touch.presses - lastJumpPresses
        lastJumpPresses = touch.presses
        if controller.state.jumpHeld && !lastControllerJump { presses += 1 }
        lastControllerJump = controller.state.jumpHeld
        return (input, presses)
    }

    // MARK: Title (attract mode)

    private func updateTitle(_ dt: Double) {
        let sim = session.sim
        let input = titleDemo.input(for: sim, dt: dt)
        var events: [SimEvent] = []
        accumulator += dt
        var first = true
        while accumulator >= GameEngine.step {
            accumulator -= GameEngine.step
            var i = input
            if !first { i.jumpPressed = false }
            first = false
            events += sim.step(dt: GameEngine.step, input: i)
        }
        // The demo never ends: hits and rescues just restart the level.
        if events.contains(where: { if case .hit = $0 { return true }; if case .rescued = $0 { return true }; return false }) {
            sim.load(sim.level)
        }
        for event in events { if case .barrelThrown(let b) = event { bossThrew(b, sound: false) } }
        syncPlay(dt, phase: .play)
    }

    // MARK: Intro

    private func startIntro(at time: Double = 0) {
        buildLevel(session.level, tilt: 0)
        let timeline = IntroTimeline(level: session.level)
        intro = timeline
        introSoundtrack = IntroSoundtrack(timeline: timeline)
        introTime = reducedMotion ? timeline.tiltEnd : min(max(0, time), timeline.end)
        lastThumped = timeline.tilts(at: introTime).filter { $0 < 1 }.count
        AudioSystem.shared.stopIntro()
        if timeline.phase(at: introTime) == .path {
            AudioSystem.shared.play("intro", looping: true)
        }
    }

    private var lastThumped = 0

    private func finishIntro() {
        AudioSystem.shared.stopIntro()
        intro = nil
        introSoundtrack = nil
        handle(session.beginPlay())
        buildLevel(session.level, tilt: 1)
    }

    private func updateIntro(_ dt: Double) {
        guard let intro else { return finishIntro() }
        let previousTime = introTime
        introTime += dt
        let phase = intro.phase(at: introTime)
        if phase == .done { return finishIntro() }
        // Leave space for the signature, stamp and falling steel after the march.
        if intro.phase(at: previousTime) == .path && phase != .path {
            AudioSystem.shared.stop("intro")
        }
        for cue in introSoundtrack?.cues(after: previousTime, through: introTime) ?? [] {
            AudioSystem.shared.play(cue.sound.rawValue, rate: cue.rate)
        }
        let level = session.level

        let tilts = intro.tilts(at: introTime)
        applyTilts(tilts, level: level)
        let segments = zip(level.girders, tilts).map { Segment($0.0).tilted($0.1) }
        // Each girder lands its tilt with a thump and a shake.
        for landed in tilts.indices.reversed() where tilts[landed] >= 1 && landed < lastThumped {
            lastThumped = landed
            shake = max(shake, 0.25)
            Haptics.impact(.rigid, intensity: 0.7)
            let s = segments[landed]
            for fx in stride(from: s.x1 + 60, to: s.x2, by: 160) {
                scene.addParticleSystem(Effects.dust(), transform: SCNMatrix4MakeTranslation(WorldSpace.x(fx), WorldSpace.y(s.y(at: fx)) + 0.05, 0.4))
            }
        }

        // Boss follows the path, carrying Motzfeldt, then signs and gloats.
        let pose = intro.pose(at: introTime)
        let bossFloor = level.girders.count - 2
        var bossPos: SCNVector3
        if phase == .path {
            bossPos = WorldSpace.point(pose.x, pose.y)
            switch pose.action {
            case .climb: boss.set(.climb); boss.targetYaw = .pi
            case .drop: boss.set(.idle); boss.targetYaw = 0
            default:
                boss.set(pose.carrying ? .carry : .walk)
                boss.targetYaw = pose.facingLeft ? -1.3 : 1.3
            }
        } else {
            let x = level.boss.x
            bossPos = WorldSpace.point(x, segments[bossFloor].y(at: x))
            boss.set(phase == .sign ? .sign : .rage)
            boss.targetYaw = phase == .sign ? 0 : -0.5
        }
        boss.root.position = bossPos
        boss.update(dt: Float(dt), speed: phase == .path ? 10 : 0)

        let rescueX = level.rescue.x + level.rescue.width / 2
        if phase == .path && pose.carrying {
            motz.set(.carried)
            // Slung over his shoulder, kicking, low enough to clear the girder above.
            let back: Float = pose.action == .climb ? 0 : (pose.facingLeft ? 0.35 : -0.35)
            motz.root.position = SCNVector3(bossPos.x + back, bossPos.y + boss.height * 0.72, bossPos.z + (pose.action == .climb ? -0.45 : 0.25))
            motz.targetYaw = pose.facingLeft ? -0.3 : 0.3
            motz.root.eulerAngles.z = pose.facingLeft ? -1.45 : 1.45
        } else {
            motz.root.eulerAngles.z = 0
            motz.set(.wave)
            motz.targetYaw = -0.4
            motz.root.position = WorldSpace.point(rescueX, segments[segments.count - 1].y(at: rescueX))
        }
        motz.update(dt: Float(dt))

        let spawn = level.playerSpawn
        lokke.root.position = WorldSpace.point(spawn.x, segments[0].y(at: spawn.x))
        lokke.targetYaw = 0.5
        lokke.set(phase == .card ? .walk : .idle)
        lokke.update(dt: Float(dt), speed: 0.4)
        lokke.root.isHidden = phase == .path
        helpBubble.isHidden = !(phase == .card || phase == .tilt)
        helpBubble.position = SCNVector3(motz.root.position.x + 0.75, motz.root.position.y + 1.55, 0.2)
        savedBubble.isHidden = true
        gloatBubble.isHidden = true
        barrelNodes.values.forEach { $0.isHidden = true }
    }

    // MARK: Play

    private func updateGame(_ dt: Double, controller: ControllerInput) {
        let phase = session.phase
        if phase == .paused || phase == .gameOver {
            if phase == .gameOver { _ = session.update(dt: dt, input: InputState()) }
            syncPlay(dt, phase: phase)
            return
        }
        var (input, presses) = mergedInput(controller)
        if options.autopilot {
            input = autopilot.input(for: session.sim, dt: dt)
            presses = input.jumpPressed ? 1 : 0
        }
        var events: [SimEvent] = []
        accumulator += dt
        while accumulator >= GameEngine.step {
            accumulator -= GameEngine.step
            var i = input
            i.jumpPressed = presses > 0
            if presses > 0 { presses -= 1 }
            events += session.update(dt: GameEngine.step, input: i)
        }
        handle(events)
        syncPlay(dt, phase: session.phase)
    }

    private func handle(_ events: [SimEvent]) {
        let audio = AudioSystem.shared
        for event in events {
            switch event {
            case .jump:
                audio.play("jump")
                Haptics.impact(.light, intensity: 0.6)
            case .barrelThrown(let b):
                bossThrew(b, sound: true)
            case .barrelLanded(let b):
                if b.thrown {
                    scene.addParticleSystem(Effects.dust(), transform: SCNMatrix4MakeTranslation(WorldSpace.x(b.x), WorldSpace.y(b.y + Barrel.radius), 0))
                    barrelNodes[b.id]?.childNodes.first?.removeAllParticleSystems()
                    shake = max(shake, 0.12)
                }
            case .barrelJumped(let b):
                audio.play("score")
                Haptics.impact(.soft, intensity: 0.8)
                Effects.floatText("+\(ScoreRules.barrelJumpPoints)", color: UIColor(hex: 0xffd24a), at: WorldSpace.point(b.x, b.y - 30, z: 0.4), in: fxRoot)
            case .hit:
                audio.play("hit")
                audio.pauseMusic()
                shake = max(shake, 0.6)
                Haptics.notify(.error)
                Haptics.impact(.heavy)
                let p = lokke.root.position
                scene.addParticleSystem(Effects.sparks(), transform: SCNMatrix4MakeTranslation(p.x, p.y + 0.6, 0.3))
                lokke.set(.hit)
                bossMoodTimer = 2.5
            case .lifeLost:
                break
            case .retry:
                audio.play("retry")
                audio.resumeMusic()
                buildLevel(session.level, tilt: 1)
                lokke.set(.idle)
            case .gameOver:
                audio.stopMusic()
                audio.play("gameOver")
            case .rescued:
                break
            case .levelComplete:
                audio.stopMusic()
                audio.play("rescue")
                audio.play("victory")
                Haptics.notify(.success)
                let p = motz.root.position
                for color in [UIColor(hex: 0xc8102e), UIColor.white] {
                    scene.addParticleSystem(Effects.confetti(color), transform: SCNMatrix4MakeTranslation(p.x, p.y + 0.8, 0.3))
                }
                Effects.floatText("+\(ScoreRules.levelCompletePoints)", color: UIColor(hex: 0x7dffb0), at: SCNVector3(p.x, p.y + 2.2, 0.5), in: fxRoot, scale: 0.55)
            case .levelStarted(let index):
                audio.play("levelStart")
                audio.startMusic(level: index)
                buildLevel(session.level, tilt: 1)
                lokke.set(.idle)
            case .ladderExit:
                break
            }
        }
    }

    private func bossThrew(_ barrel: Barrel, sound: Bool) {
        if sound { AudioSystem.shared.play("throw") }
        bossThrowTimer = 0.35
        let node = barrelNode(barrel.id)
        node.childNodes.first?.removeAllParticleSystems()
        if barrel.thrown { node.childNodes.first?.addParticleSystem(Effects.fireTrail()) }
    }

    private func barrelNode(_ id: Int) -> SCNNode {
        if let n = barrelNodes[id] { return n }
        let holder = SCNNode()
        let trail = SCNNode()
        holder.addChildNode(trail)
        holder.addChildNode(BarrelNodeFactory.make())
        levelRoot.addChildNode(holder)
        barrelNodes[id] = holder
        return holder
    }

    /// Mirrors the simulation into the scene every frame.
    private func syncPlay(_ dt: Double, phase: GamePhase) {
        let sim = session.sim
        let level = sim.level
        let fdt = Float(dt)
        let p = sim.player

        // Jumpman Løkke
        lokke.root.isHidden = false
        let targetZ: Float = p.isClimbing ? WorldBuilder.ladderZ + 0.2 : 0
        var pos = WorldSpace.point(p.x, p.feet)
        pos.z = lokke.root.position.z + (targetZ - lokke.root.position.z) * min(1, fdt * 12)
        lokke.root.position = pos
        if phase == .levelComplete {
            lokke.set(.cheer)
            lokke.targetYaw = 0.3
        } else if p.mode == .hit || phase == .lifeLost || phase == .retrying || phase == .gameOver {
            lokke.set(.hit)
        } else if p.isClimbing {
            lokke.set(p.vy != 0 ? .climb : .climbIdle)
            lokke.targetYaw = .pi
        } else if p.isAirborne {
            lokke.set(p.vy < 0 ? .jump : .fall)
            lokke.targetYaw = Float(p.facing) * 1.15
        } else if p.vx != 0 {
            lokke.set(.walk)
            lokke.targetYaw = Float(p.facing) * 1.15
        } else {
            lokke.set(.idle)
            if lokke.pose == .idle && abs(lokke.targetYaw) > 2 { lokke.targetYaw = 0.6 }
        }
        if phase != .paused {
            lokke.update(dt: fdt, speed: Float(max(abs(p.vx), abs(p.vy))) / 40)
        }
        // Blink while invulnerable after a retry.
        lokke.root.opacity = 1

        // The boss: wind-up before each throw, chest-thumping tantrums in between.
        let bp = sim.bossPosition
        boss.root.position = WorldSpace.point(bp.x, bp.y)
        bossThrowTimer -= dt
        bossMoodTimer -= dt
        if phase == .levelComplete {
            boss.set(.rage)
            boss.targetYaw = 0
        } else if bossMoodTimer > 0 || phase == .gameOver {
            boss.set(.cheer)
            boss.targetYaw = -0.3
        } else if bossThrowTimer > 0 {
            boss.set(.throwing)
            boss.targetYaw = -0.9
        } else if let t = sim.barrels.timeToNextSpawn, t < sim.barrels.settings.windup, phase == .play {
            boss.set(.windup)
            boss.targetYaw = -0.6
        } else {
            boss.set(sin(clock * 0.9) > 0.55 ? .rage : .idle)
            boss.targetYaw = -0.55
        }
        if phase != .paused { boss.update(dt: fdt) }
        gloatBubble.isHidden = !(bossMoodTimer > 0 || phase == .gameOver)
        gloatBubble.position = SCNVector3(boss.root.position.x - 0.9, boss.root.position.y + 2.5, 0.4)

        // Motzfeldt
        let rescueX = level.rescue.x + level.rescue.width / 2
        motz.root.position = WorldSpace.point(rescueX, level.rescue.y + level.rescue.height)
        motz.root.eulerAngles.z = 0
        if phase == .levelComplete {
            motz.set(.cheer)
            motz.targetYaw = -0.6
        } else {
            motz.set(.wave)
            motz.targetYaw = -0.35
        }
        if phase != .paused { motz.update(dt: fdt) }
        rescueLight.position = SCNVector3(motz.root.position.x, motz.root.position.y + 2, 1.5)
        helpBubble.isHidden = phase == .levelComplete
        helpBubble.position = SCNVector3(motz.root.position.x + 0.75, motz.root.position.y + 1.55 + Float(sin(clock * 3)) * 0.05, 0.2)
        savedBubble.isHidden = phase != .levelComplete
        savedBubble.position = SCNVector3(motz.root.position.x + 0.2, motz.root.position.y + 1.7, 0.3)

        // Barrels
        var seen = Set<Int>()
        for barrel in sim.barrels.active {
            seen.insert(barrel.id)
            let node = barrelNode(barrel.id)
            node.isHidden = false
            node.position = WorldSpace.point(barrel.x, barrel.y)
            node.childNodes[1].eulerAngles = SCNVector3(0, 0, Float(barrel.rotation))
            if barrel.mode != .thrown, node.childNodes.first?.particleSystems?.isEmpty == false {
                node.childNodes.first?.removeAllParticleSystems()
            }
        }
        for (id, node) in barrelNodes where !seen.contains(id) && !node.isHidden {
            node.isHidden = true
            node.childNodes.first?.removeAllParticleSystems()
        }

        // Footsteps
        if phase == .play {
            if p.isGrounded && p.vx != 0 { AudioSystem.shared.step(now: clock) }
            if p.isClimbing && p.vy != 0 { AudioSystem.shared.step(now: clock, interval: 0.24) }
        }
    }

    // MARK: - Ambience & camera

    private func updateAmbience(_ dt: Double) {
        craneJib.eulerAngles.y = Float(sin(clock * 0.05) * 0.8)
        let blink = sin(clock * 4) > 0.2
        beacons.forEach { $0.isHidden = !blink }
        sign.opacity = CGFloat(0.9 + 0.1 * sin(clock * 23) * (sin(clock * 0.7) > 0.93 ? 1 : 0))
    }

    private func desiredCamera() -> (pos: SIMD3<Float>, target: SIMD3<Float>, rate: Float, dof: Bool) {
        let phase = session.phase
        switch phase {
        case .title where options.iconShot:
            let b = boss.root.position
            let target = SIMD3<Float>(b.x - 0.1, b.y + 1.5, 0)
            return (target + SIMD3(-0.9, 0.15, 1.9), target, 20, false)
        case .title:
            let a = Float(sin(clock * 0.09)) * 0.75
            let target = SIMD3<Float>(0, 7.2, 0)
            return (target + SIMD3(sin(a) * 27, 2.5 + Float(sin(clock * 0.13)) * 1.5, cos(a) * 27), target, 1.5, false)
        case .intro:
            guard let intro else { break }
            let bp = boss.root.position
            switch intro.phase(at: introTime) {
            case .path:
                let target = SIMD3<Float>(bp.x * 0.7, bp.y + 1.4, 0)
                return (target + SIMD3(1.5, 1.2, 12), target, 2.5, false)
            case .sign:
                let target = SIMD3<Float>(bp.x - 0.6, bp.y + 1.3, 0)
                return (target + SIMD3(-1.2, 0.8, 6.5), target, 2.5, true)
            case .tilt, .card, .done:
                let target = SIMD3<Float>(0, 7, 0)
                return (target + SIMD3(0, 1, 26), target, 2, false)
            }
        case .levelComplete:
            let m = motz.root.position
            let target = SIMD3<Float>(m.x - 0.3, m.y + 0.8, 0)
            let a = Float(session.phaseTime) * 0.35 - 0.3
            return (target + SIMD3(sin(a) * 6.5, 1.2, cos(a) * 6.5), target, 2.2, true)
        case .gameOver:
            let target = SIMD3<Float>(0, 7, 0)
            let a = Float(sin(clock * 0.1)) * 0.5
            return (target + SIMD3(sin(a) * 24, 3, cos(a) * 24), target, 1, false)
        default:
            break
        }
        let p = lokke.root.position
        let hit = phase == .lifeLost || phase == .retrying
        let target = SIMD3<Float>(p.x * 0.62, min(max(p.y + 1.6, 4.6), 11.2), 0)
        let distance: Float = hit ? 10 : 15.5
        return (target + SIMD3(p.x * 0.14, 1.1, distance), target, hit ? 3 : 4, false)
    }

    private func updateCamera(_ dt: Double) {
        let desired = desiredCamera()
        let k = 1 - exp(-desired.rate * Float(dt))
        camPos += (desired.pos - camPos) * k
        camTarget += (desired.target - camTarget) * k
        shake = max(0, shake - Float(dt) * 1.8)
        var jitter = SIMD3<Float>(0, 0, 0)
        if shake > 0 && !reducedMotion {
            let s = shake * shake
            jitter = SIMD3(Float(sin(clock * 91)) * s * 0.5, Float(sin(clock * 73 + 1)) * s * 0.4, 0)
        }
        cameraNode.position = SCNVector3(camPos.x + jitter.x, camPos.y + jitter.y, camPos.z)
        cameraNode.look(at: SCNVector3(camTarget.x + jitter.x, camTarget.y + jitter.y, camTarget.z))
        if let camera = cameraNode.camera {
            camera.wantsDepthOfField = desired.dof
            camera.focusDistance = CGFloat(simd_length(camTarget - camPos))
        }
    }

    // MARK: - HUD

    private func publishHUD() {
        var hud = HUDState()
        hud.phase = session.phase
        hud.runID = session.runID
        hud.completedRun = options.autopilot || options.autostart || options.iconShot || options.introAt != nil ? nil : session.completedRun
        hud.score = session.stats.score
        hud.best = session.best
        hud.lives = session.stats.lives
        hud.level = session.stats.levelIndex + 1
        hud.levelName = session.level.name
        if let intro, session.phase == .intro {
            hud.introPhase = intro.phase(at: introTime)
            hud.signProgress = min(1, max(0, (introTime - intro.pathEnd) / (IntroTiming.sign * 0.8)))
        }
        hud.ladderHint = session.phase == .play && session.stats.levelIndex == 0 && session.sim.time < 6
        guard hud != lastHUD else { return }
        #if DEBUG
        if hud.phase != lastHUD?.phase { print("[DT3D] t=\(String(format: "%.1f", clock)) phase=\(hud.phase) level=\(hud.level) score=\(hud.score) lives=\(hud.lives)") }
        #endif
        lastHUD = hud
        let sink = hudSink
        DispatchQueue.main.async { sink?(hud) }
    }
}
