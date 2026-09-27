import SwiftUI

/// Approximate activity feedback, never a timer that delays game readiness.
struct LoadingScreenView: View {
    @State private var progress = 0.15
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 6 / 255, green: 16 / 255, blue: 39 / 255).ignoresSafeArea()
            Image("LaunchCover")
                .resizable().scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text("Loading…").font(.headline).foregroundStyle(.white)
                ProgressView(value: progress)
                    .progressViewStyle(.linear).tint(.yellow)
                    .accessibilityLabel("Loading game")
                    .accessibilityValue("Please wait")
                    .accessibilityIdentifier("startupProgress")
            }
            .padding(16)
            .frame(maxWidth: 340)
            .background(Color(red: 6 / 255, green: 16 / 255, blue: 39 / 255).opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20).padding(.bottom, 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("startupLoadingScreen")
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(150)) }
                catch { return }
                // Approach 90% while rendering starts; readiness removes the
                // view immediately, without waiting for a completed animation.
                withAnimation(reduceMotion ? nil : .linear(duration: 0.15)) {
                    progress += (0.9 - progress) * 0.08
                }
            }
        }
    }
}
