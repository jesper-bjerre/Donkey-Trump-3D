import SwiftUI

struct ReportsView: View {
    let coordinator: ReportCoordinator
    var closeLabel = "Back to Highscores"
    @AccessibilityFocusState private var resultFocused: Bool
    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    Button(closeLabel) { coordinator.close() }.accessibilityIdentifier("reportClose")
                    Button("My Reports") { coordinator.history() }.accessibilityIdentifier("reportHistory")
                    Link("Support", destination: SupportLinks.support)
                    Link("Privacy", destination: SupportLinks.privacy)
                }.padding(.vertical, 4)
            }
            switch coordinator.state {
            case .form: HighscoreReportView(coordinator: coordinator)
            case .waiting: ProgressView("Waiting for report response…").accessibilityIdentifier("reportWaiting")
            case .history:
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Reports").font(.title2.bold())
                        if coordinator.receipts.isEmpty { Text("No saved report receipts on this iPhone.") }
                        ForEach(coordinator.receipts) { receipt in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(receipt.updatedAt, style: .date)
                                    Text(receipt.status.capitalized)
                                }
                                Spacer()
                                Button("Check Status") { coordinator.check(receipt.id) }
                            }.padding(8)
                        }
                    }.padding()
                }
            case .result(let id, let message):
                ScrollView {
                    VStack(spacing: 16) {
                        Text(message).accessibilityIdentifier("reportResult")
                            .accessibilityFocused($resultFocused)
                            .task(id: message) { resultFocused = true }
                        Button("Check Status") { coordinator.check(id) }.buttonStyle(.bordered).accessibilityIdentifier("reportCheckStatus")
                    }.padding()
                }
            case .closed: EmptyView()
            }
        }
        .onChange(of: coordinator.state) { _, state in
            if case .result = state { resultFocused = true }
            else { resultFocused = false }
        }
    }
}
