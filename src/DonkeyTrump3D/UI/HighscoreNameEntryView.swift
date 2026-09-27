import SwiftUI

struct HighscoreNameEntryView: View {
    let error: String?
    let submit: (String) -> Void
    let cancel: () -> Void
    @State private var name = ""
    @FocusState private var editing: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    dialog(compact: geometry.size.height < 210)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func dialog(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if !compact {
                Label("New highscore!", systemImage: "trophy.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.yellow)
                    .accessibilityAddTraits(.isHeader)
            }
            // Preserve the same text field and focus as keyboard space changes.
            let layout = compact ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 14))
            layout {
                VStack(alignment: .leading, spacing: 6) {
                    if !compact { Text("Name").font(.subheadline.bold()) }
                    nameField
                }
                HStack(spacing: 12) {
                    cancelButton
                    submitButton
                }
            }
            if let error {
                Text(error).font(.callout).foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("highscoreNameError")
            }
        }
        .padding(compact ? 8 : 20)
        .frame(maxWidth: compact ? 760 : 560)
        .background(Color(red: 0.07, green: 0.10, blue: 0.16), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("highscoreNameDialog")
        .padding(.horizontal, 4)
    }

    private var nameField: some View {
        TextField("", text: $name, prompt: Text("Enter name").foregroundStyle(Color.black.opacity(0.55)))
            .font(.body)
            .foregroundStyle(.black)
            .tint(Color(red: 0.55, green: 0.3, blue: 0))
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minWidth: 120, minHeight: 48)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture { editing = true }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(editing ? Color.yellow : .white.opacity(0.4), lineWidth: 3)
                    .allowsHitTesting(false)
            }
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($editing)
            .accessibilityLabel("Name")
            .accessibilityIdentifier("highscoreName")
            .onSubmit(publish)
    }

    private var submitButton: some View {
        Button(action: publish) {
            Text("Submit").font(.body.bold()).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityIdentifier("highscoreSubmit")
    }

    private var cancelButton: some View {
        Button {
            editing = false
            cancel()
        } label: {
            Text("Cancel").font(.body.weight(.semibold)).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityIdentifier("highscoreCancel")
    }

    private func publish() {
        editing = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        submit(name)
    }
}
