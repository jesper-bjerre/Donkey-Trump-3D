import SwiftUI

struct HighscoreListView: View {
    let browse: HighscoreBrowse
    var report: ((UUID) -> Void)? = nil
    @AccessibilityFocusState private var focusedEntry: UUID?
    @State private var didFocus = false

    var body: some View {
        VStack(spacing: 4) {
            if browse.stale { Text("Previously loaded — may be out of date.").font(.callout).foregroundStyle(.orange).accessibilityIdentifier("highscoreStale") }
            if let message = browse.message { Text(message).font(.callout).multilineTextAlignment(.center) }
            if browse.snapshot.entries.isEmpty {
                ContentUnavailableView("No scores yet", systemImage: "trophy", description: Text("Be the first to join the list."))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(browse.snapshot.entries) { entry in
                                let selected = browse.anchor == .highlight(entry.id)
                                HStack(alignment: .firstTextBaseline, spacing: 14) {
                                    Text("\(entry.rank)").monospacedDigit().frame(minWidth: 36, alignment: .trailing)
                                    Text(verbatim: entry.displayName).frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(entry.score)").monospacedDigit()
                                    if let report {
                                        Button { report(entry.id) } label: { Image(systemName: "flag") .frame(minWidth: 44, minHeight: 44) }
                                            .accessibilityLabel("Report name at rank \(entry.rank)")
                                            .accessibilityIdentifier("reportEntry\(entry.rank)")
                                    }
                                    if selected { Image(systemName: "star.fill").accessibilityHidden(true) }
                                }
                                .font(.body.weight(selected ? .bold : .regular))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selected ? Color.orange.opacity(0.3) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                                .id(entry.id)
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("Rank \(entry.rank), \(entry.displayName), \(entry.score) points" + (selected ? ", Your result" : ""))
                                .accessibilityIdentifier(selected ? "highscoreSelectedRow" : "highscoreRow\(entry.rank)")
                                .accessibilityFocused($focusedEntry, equals: entry.id)
                            }
                        }
                    }
                    .accessibilityIdentifier("highscoreList")
                    .onAppear { position(proxy) }
                    .onChange(of: browse.anchor) { _, _ in position(proxy) }
                    .onChange(of: browse.snapshot.revision) { _, _ in position(proxy) }
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { _ in position(proxy) }
                }
            }
        }
        #if DEBUG
        .background { HighscoreRenderProbe(kind: "list", marker: browse.snapshot.revision) }
        .task(id: browse.snapshot.revision) { HighscoreIntegrationEvidence.save(browse.snapshot) }
        #endif
    }
    private func position(_ proxy: ScrollViewProxy) {
        let id: UUID?, anchor: UnitPoint
        switch browse.anchor {
        case .top: id = browse.snapshot.entries.first?.id; anchor = .top
        case .bottom: id = browse.snapshot.entries.last?.id; anchor = .bottom
        case .highlight(let selected): id = selected; anchor = .center
        }
        guard let id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(id, anchor: anchor)
            if case .highlight = browse.anchor, !didFocus { didFocus = true; focusedEntry = id }
        }
    }
}

struct HighscorePanel: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let model: GameModel
    private var coordinator: HighscoreCoordinator { model.highscores }
    private var isEnteringName: Bool {
        if case .enteringName = coordinator.state { return true }
        return false
    }
    var body: some View {
        GeometryReader { geometry in
            panel(compact: isEnteringName && geometry.size.height < 300)
        }
    }
    private func panel(compact: Bool) -> some View {
        VStack(spacing: 8) {
            if !compact {
            HStack {
                Text("Highscores").font(.title2.bold())
                Spacer()
                if model.hud.phase == .gameOver {
                    Text("Final score: \(model.hud.score)").font(.headline).monospacedDigit().accessibilityIdentifier("highscoreFinalScore")
                }
                if case .browsing = coordinator.state {
                    Button { coordinator.refresh() } label: { Label("Refresh list", systemImage: "arrow.clockwise").labelStyle(.iconOnly) }.accessibilityIdentifier("highscoreRefresh")
                } else if case .failed = coordinator.state {
                    Button { coordinator.refresh() } label: { Label("Retry list", systemImage: "arrow.clockwise").labelStyle(.iconOnly) }.accessibilityIdentifier("highscoreRefresh")
                }
                Button { model.reports.history() } label: { Label("My Reports", systemImage: "tray").labelStyle(.iconOnly) }.accessibilityIdentifier("openReports")
                Button { model.reports.close(); coordinator.cancel() } label: { Label("Close", systemImage: "xmark.circle").labelStyle(.iconOnly) }.accessibilityIdentifier("highscoreClose")
            }
            .layoutPriority(1)
            }
            Group {
                if model.reports.isPresented { ReportsView(coordinator: model.reports) }
                else { switch coordinator.state {
                case .closed: EmptyView()
                case .loading: ProgressView("Loading highscores…").accessibilityIdentifier("highscoreLoading")
                case .enteringName(_, let error): HighscoreNameEntryView(error: error, submit: { coordinator.submit(name: $0) }, cancel: { coordinator.cancel() })
                case .submitting: ProgressView("Submitting score…").accessibilityIdentifier("highscoreSubmitting")
                case .browsing(let browse): HighscoreListView(browse: browse, report: { model.reports.open(entryId: $0) })
                case .failed(let message, let cached):
                    VStack {
                        ScrollView { Text(message).multilineTextAlignment(.center).accessibilityIdentifier("highscoreError") }
                            .frame(maxHeight: cached == nil ? .infinity : 90)
                        if let cached { HighscoreListView(browse: cached, report: { model.reports.open(entryId: $0) }) }
                    }
                    #if DEBUG
                    .background { HighscoreRenderProbe(kind: "failure", marker: message) }
                    #endif
                }
            }
            }
            .frame(minHeight: 0, maxHeight: .infinity).clipped()
            HStack {
                if compact {
                    Text("Final score: \(model.hud.score)")
                        .font(.caption.bold()).monospacedDigit()
                        .accessibilityIdentifier("highscoreFinalScore")
                    Spacer(minLength: 8)
                    Button { model.send(.restart) } label: {
                        Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }.accessibilityLabel("Play Again")
                    Button { model.send(.toTitle) } label: {
                        Image(systemName: "house").frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }.accessibilityLabel("Return to Title")
                    Button { coordinator.cancel() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }.accessibilityLabel("Close").accessibilityIdentifier("highscoreClose")
                } else if model.hud.phase == .gameOver {
                    Button("Play Again") { model.send(.restart) }.buttonStyle(.borderedProminent)
                    Button("Return to Title") { model.send(.toTitle) }.buttonStyle(.bordered)
                } else {
                    Button("Start Game") { model.send(.startGame) }.buttonStyle(.borderedProminent)
                    Button { model.showHowTo = true } label: {
                        if textSize.isAccessibilitySize { Image(systemName: "questionmark.circle").accessibilityLabel("How to Play") }
                        else { Text("How to Play") }
                    }.buttonStyle(.bordered)
                    Button { model.muted.toggle() } label: { Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill") }
                        .accessibilityLabel(model.muted ? "Sound off" : "Sound on")
                    Button { model.haptics.toggle() } label: { Image(systemName: "iphone.radiowaves.left.and.right") }
                        .accessibilityLabel(model.haptics ? "Haptics on" : "Haptics off")
                }
            }
            .font(compact ? .system(size: 22, weight: .semibold) : .body)
            .foregroundStyle(compact ? .white : .primary)
            .layoutPriority(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(isEnteringName ? 0.72 : 0.94))
    }
}
