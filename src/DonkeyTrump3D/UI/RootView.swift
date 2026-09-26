import SwiftUI

extension Font {
    static func arcade(_ size: CGFloat, _ weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension ShapeStyle where Self == LinearGradient {
    static var gold: LinearGradient {
        LinearGradient(colors: [Color(red: 1, green: 0.93, blue: 0.55), Color(red: 1, green: 0.72, blue: 0.16), Color(red: 0.8, green: 0.45, blue: 0.05)], startPoint: .top, endPoint: .bottom)
    }
}

struct RootView: View {
    let model: GameModel

    private var hud: HUDState { model.hud }
    private var inGame: Bool { ![.title, .intro].contains(hud.phase) }

    var body: some View {
        ZStack {
            GameSceneView(engine: model.engine)
                .ignoresSafeArea()

            if hud.phase == .play {
                TouchControlsLayer(hub: model.engine.inputHub)
                    .ignoresSafeArea()
            }

            switch hud.phase {
            case .title where LaunchOptions.current.iconShot:
                EmptyView()
            case .title:
                if !model.highscores.state.isPresented {
                    TitleView(model: model).transition(.opacity)
                }
            case .intro:
                IntroOverlay(hud: hud) { model.send(.skipIntro) }
                    .transition(.opacity)
            default:
                GameHUD(hud: hud) { model.send(.pause) }
                if !model.highscores.state.isPresented { PhaseOverlay(model: model) }
            }
            if model.highscores.state.isPresented && (hud.phase == .title || hud.phase == .gameOver) {
                HighscorePanel(model: model)
            }
        }
        #if DEBUG
        .background {
            if hud.phase == .intro || hud.phase == .play {
                HighscoreRenderProbe(kind: "game", marker: "\(hud.runID?.uuidString ?? "none")-\(hud.phase)")
            }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("-highscoreOpenOnLaunch"),
               case .integration = HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) { model.highscores.openTitle() }
            await HighscorePerformanceHarness.shared.run(model)
        }
        .overlay(alignment: .bottomLeading) {
            if HighscorePerformanceHarness.shared.isEnabled {
                Text(verbatim: HighscorePerformanceHarness.shared.result).font(.system(size: 1)).foregroundStyle(.clear)
                    .accessibilityIdentifier("highscorePerformanceResult")
            }
        }
        .overlay(alignment: .topLeading) {
            if HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) != nil {
                Text(verbatim: "reads=\(UserDefaults.standard.integer(forKey: "highscoreFixtureReads"));posts=\(UserDefaults.standard.integer(forKey: "highscoreFixturePosts"));best=\(hud.best)")
                    .font(.system(size: 1)).foregroundStyle(.clear)
                    .accessibilityIdentifier("highscoreTestEvidence")
            }
        }
        #endif
        .animation(.easeInOut(duration: 0.35), value: hud.phase)
        .sheet(isPresented: Binding(get: { model.showHowTo }, set: { model.showHowTo = $0 })) {
            HowToPlayView()
                .presentationDetents([.large])
        }
    }
}

// MARK: - Title

struct TitleView: View {
    let model: GameModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Text(Copy.title)
                        .font(.arcade(62))
                        .italic()
                        .foregroundStyle(.gold)
                        .shadow(color: Color(red: 0.6, green: 0.1, blue: 0.05), radius: 0, x: 3, y: 4)
                        .shadow(color: .black.opacity(0.6), radius: 14, y: 6)
                    Text("3D")
                        .font(.arcade(20))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(red: 0.8, green: 0.08, blue: 0.12)))
                        .rotationEffect(.degrees(12))
                        .offset(x: 26, y: -12)
                }
                Text(Copy.tagline)
                    .font(.arcade(18, .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 6)
                Spacer()
                if model.hud.best > 0 {
                    Text("BEST \(model.hud.best)")
                        .font(.arcade(15, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(.gold)
                        .padding(.bottom, 4)
                }
                HStack(spacing: 14) {
                    Button {
                        model.send(.startGame)
                    } label: {
                        Label(Copy.start, systemImage: "play.fill")
                            .font(.arcade(20))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color(red: 0.85, green: 0.12, blue: 0.1))

                    Button { model.highscores.openTitle() } label: {
                        Label("Highscores", systemImage: "trophy")
                            .font(.arcade(16, .bold)).padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("highscoreOpen")

                    Button {
                        model.showHowTo = true
                    } label: {
                        Label(Copy.howTo, systemImage: "questionmark.circle")
                            .font(.arcade(16, .bold))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)

                    Button {
                        model.muted.toggle()
                    } label: {
                        Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(model.muted ? "Sound off" : "Sound on")

                    Button {
                        model.haptics.toggle()
                    } label: {
                        Image(systemName: model.haptics ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(model.haptics ? "Haptics on" : "Haptics off")
                }
                Text(Copy.accountFree + "  ·  " + Copy.parody)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
        }
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Copy.howToGoal)
                        .font(.body.weight(.semibold))
                    ForEach(Copy.howToLines, id: \.text) { line in
                        Label {
                            Text(line.text)
                        } icon: {
                            Image(systemName: line.icon)
                                .foregroundStyle(.orange)
                                .frame(width: 28)
                        }
                    }
                    Text(Copy.privacy)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .navigationTitle(Copy.howTo)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Intro

struct IntroOverlay: View {
    let hud: HUDState
    let skip: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: skip)
            if hud.introPhase == .sign {
                ExecutiveOrderCard(progress: hud.signProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 44)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            if hud.introPhase == .card {
                VStack(spacing: 10) {
                    Text("LEVEL \(hud.level)")
                        .font(.arcade(20))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(hud.levelName)
                        .font(.arcade(40))
                        .foregroundStyle(.gold)
                    Text(Copy.cardGoal)
                        .font(.arcade(20, .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 22)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
                .transition(.scale.combined(with: .opacity))
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: skip) {
                        Label(Copy.skip, systemImage: "forward.end.fill")
                            .font(.arcade(15, .bold))
                    }
                    .buttonStyle(.glass)
                }
                Spacer()
            }
            .padding(16)
        }
        .animation(.spring(duration: 0.5), value: hud.introPhase)
    }
}

struct ExecutiveOrderCard: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "seal.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color(red: 0.7, green: 0.55, blue: 0.2))
            Text(Copy.orderTitle)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .tracking(1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Rectangle().frame(height: 1).opacity(0.4)
            Text(Copy.orderText)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            HStack(alignment: .bottom) {
                Text(Copy.orderSeal)
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .opacity(0.6)
                Spacer()
                ZStack(alignment: .leading) {
                    Text("D. Trump")
                        .font(.custom("SnellRoundhand-Black", size: 30))
                        .foregroundStyle(Color(red: 0.1, green: 0.16, blue: 0.55))
                        .fixedSize()
                        .mask(alignment: .leading) {
                            GeometryReader { g in
                                Rectangle().frame(width: g.size.width * progress)
                            }
                        }
                }
                .frame(width: 130, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().frame(height: 1).opacity(0.5).offset(y: 2) }
            }
        }
        .foregroundStyle(Color(red: 0.17, green: 0.1, blue: 0.06))
        .padding(18)
        .frame(width: 330, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.95, blue: 0.85), Color(red: 0.93, green: 0.87, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(red: 0.54, green: 0.42, blue: 0.17), lineWidth: 3))
                .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        )
        .rotationEffect(.degrees(-3))
    }
}

// MARK: - In-game HUD

struct GameHUD: View {
    let hud: HUDState
    let pause: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SCORE")
                        .font(.arcade(10, .heavy))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(hud.score)")
                        .font(.arcade(24))
                        .monospacedDigit()
                        .foregroundStyle(.gold)
                        .contentTransition(.numericText(value: Double(hud.score)))
                        .animation(.snappy, value: hud.score)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 0) {
                    Text("BEST")
                        .font(.arcade(10, .heavy))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(hud.best)")
                        .font(.arcade(16, .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(spacing: 0) {
                    Text("LEVEL \(hud.level)")
                        .font(.arcade(12, .heavy))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(hud.levelName)
                        .font(.arcade(16, .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: Capsule())

                Spacer()

                HStack(spacing: 5) {
                    ForEach(0..<ScoreRules.startingLives, id: \.self) { i in
                        Image(systemName: i < hud.lives ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(i < hud.lives ? Color(red: 1, green: 0.25, blue: 0.3) : .white.opacity(0.4))
                            .symbolEffect(.bounce, value: hud.lives)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: Capsule())
                .accessibilityLabel("Lives: \(hud.lives)")

                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .black))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Pause")
                .disabled(hud.phase != .play)
            }
            if hud.ladderHint {
                VStack(spacing: 2) {
                    Text(Copy.objective)
                        .font(.arcade(22))
                        .foregroundStyle(.gold)
                    Text(Copy.ladderHint)
                        .font(.arcade(13, .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 6)
                .shadow(radius: 6)
                .transition(.opacity)
                .allowsHitTesting(false)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .animation(.easeInOut, value: hud.ladderHint)
    }
}

// MARK: - Phase overlays

struct PhaseOverlay: View {
    let model: GameModel
    private var hud: HUDState { model.hud }

    var body: some View {
        switch hud.phase {
        case .lifeLost, .retrying:
            Banner(title: hud.phase == .lifeLost ? Copy.lifeLost : Copy.retrying, subtitle: hud.phase == .lifeLost ? "Lives left: \(hud.lives)" : nil, color: .red)
                .allowsHitTesting(false)
        case .levelComplete:
            Banner(title: Copy.rescued, subtitle: "+\(ScoreRules.levelCompletePoints)   ·   " + Copy.nextFaster, color: .green)
                .allowsHitTesting(false)
        case .paused:
            MenuPanel(title: Copy.paused) {
                Button { model.send(.resume) } label: { menuLabel(Copy.resume, "play.fill") }
                    .buttonStyle(.glassProminent)
                    .tint(Color(red: 0.85, green: 0.12, blue: 0.1))
                Button { model.send(.restart) } label: { menuLabel(Copy.restart, "arrow.counterclockwise") }
                    .buttonStyle(.glass)
                Button { model.send(.toTitle) } label: { menuLabel(Copy.toTitle, "house.fill") }
                    .buttonStyle(.glass)
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(get: { !model.muted }, set: { model.muted = !$0 })) { Label("Sound", systemImage: "speaker.wave.2.fill") }
                    Toggle(isOn: Binding(get: { model.haptics }, set: { model.haptics = $0 })) { Label("Haptics", systemImage: "iphone.radiowaves.left.and.right") }
                }
                .font(.arcade(14, .bold))
                .frame(width: 330)
            }
        case .gameOver:
            MenuPanel(title: Copy.gameOver, titleColor: Color(red: 1, green: 0.3, blue: 0.3)) {
                VStack(spacing: 4) {
                    Text("\(Copy.finalScore): \(hud.score)")
                        .font(.arcade(22))
                        .monospacedDigit()
                    Text("\(Copy.levelReached): \(hud.level)")
                        .font(.arcade(15, .bold))
                        .foregroundStyle(.white.opacity(0.8))
                    if hud.score > 0 && hud.score >= hud.best {
                        Text(Copy.newBest)
                            .font(.arcade(18))
                            .foregroundStyle(.gold)
                            .symbolEffect(.pulse)
                    }
                }
                HStack(spacing: 12) {
                    Button { model.send(.restart) } label: { menuLabel(Copy.playAgain, "arrow.counterclockwise") }
                        .buttonStyle(.glassProminent)
                        .tint(Color(red: 0.85, green: 0.12, blue: 0.1))
                    Button { model.send(.toTitle) } label: { menuLabel(Copy.toTitle, "house.fill") }
                        .buttonStyle(.glass)
                }
            }
        default:
            EmptyView()
        }
    }

    private func menuLabel(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.arcade(17, .bold))
            .frame(minWidth: 210)
            .padding(.vertical, 4)
    }
}

struct Banner: View {
    let title: String
    let subtitle: String?
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.arcade(34))
                .foregroundStyle(.white)
                .shadow(color: color.opacity(0.8), radius: 12)
            if let subtitle {
                Text(subtitle)
                    .font(.arcade(16, .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(color.opacity(0.25)), in: RoundedRectangle(cornerRadius: 26))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 36)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct MenuPanel<Content: View>: View {
    let title: String
    var titleColor: Color = .white
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(title)
                    .font(.arcade(38))
                    .foregroundStyle(titleColor)
                content
            }
            .padding(26)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
