import SwiftUI

// These owner-controlled destinations must pass live anonymous checks before release.
enum SupportLinks {
    static let support = URL(string: "https://donkeytrump-api-p.azurewebsites.net/support")!
    static let privacy = URL(string: "https://donkeytrump-api-p.azurewebsites.net/privacy")!
}

struct HighscoreReportView: View {
    let coordinator: ReportCoordinator
    @State private var reason = ReportReason.offensiveName
    @AccessibilityFocusState private var headingFocused: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Report a name").font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                Text("Choose the reason for your report.")
                Picker("Reason", selection: $reason) {
                    ForEach(ReportReason.allCases, id: \.self) { Text($0.label).tag($0) }
                }.pickerStyle(.menu).accessibilityIdentifier("reportReason")
                ViewThatFits(in: .horizontal) {
                    HStack { actions }
                    VStack(alignment: .leading, spacing: 12) { actions }
                }
            }.padding(16).frame(maxWidth: 560, alignment: .leading)
        }.frame(maxWidth: .infinity)
            .task { headingFocused = true }
    }
    @ViewBuilder private var actions: some View {
        Button("Send Report") { coordinator.send(reason: reason) }
            .buttonStyle(.borderedProminent).accessibilityIdentifier("reportSend")
        Button("Cancel") { coordinator.close() }.buttonStyle(.bordered).accessibilityIdentifier("reportCancel")
        Link("Support", destination: SupportLinks.support)
    }
}
