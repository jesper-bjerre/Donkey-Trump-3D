import SwiftUI

struct HighscoreNameEntryView: View {
    let error: String?
    let submit: (String) -> Void
    let cancel: () -> Void
    @State private var name = ""
    @FocusState private var editing: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("Your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($editing)
                    .accessibilityIdentifier("highscoreName")
                    .onSubmit(publish)
                Button("Submit", action: publish)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("highscoreSubmit")
                Button("Cancel") { editing = false; cancel() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("highscoreCancel")
            }
            ScrollView {
                VStack(spacing: 6) {
                    Text(Copy.publicScoreNotice).font(.callout)
                    if let error {
                        Text(error).foregroundStyle(.orange)
                            .accessibilityIdentifier("highscoreNameError")
                    }
                }.frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: 760)
    }
    private func publish() {
        editing = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        submit(name)
    }
}
