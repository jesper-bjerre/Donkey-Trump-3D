import Foundation

enum HighscoreSource: Equatable, Sendable { case title, completedRun(CompletedRun) }
enum HighscoreAnchor: Equatable, Sendable { case top, bottom, highlight(UUID) }
enum HighscoreRunOutcome: Sendable { case published, notQualified, cancelled, failed }

struct HighscoreBrowse: Equatable, Sendable {
    var snapshot: HighscoreSnapshot
    var anchor: HighscoreAnchor
    var finalScore: Int?
    var stale = false
    var message: String?
}

enum HighscoreState: Equatable, Sendable {
    case closed
    case loading(HighscoreSource)
    case enteringName(CompletedRun, error: String?)
    case submitting(CompletedRun)
    case browsing(HighscoreBrowse)
    case failed(message: String, cached: HighscoreBrowse?)
    var isPresented: Bool { self != .closed }
}

protocol HighscoreClock: Sendable {
    func sleepForDeadline() async throws
}
struct ContinuousHighscoreClock: HighscoreClock {
    func sleepForDeadline() async throws { // Reserve 200 ms for presenting the terminal state within the eight-second UI limit.
        try await Task.sleep(for: .milliseconds(7800)) }
}

extension HighscoreBrowse {
    func refreshed(with snapshot: HighscoreSnapshot) -> Self {
        var result = self
        result.snapshot = snapshot; result.stale = false
        if case .highlight(let id) = anchor, !snapshot.entries.contains(where: { $0.id == id }) {
            result.anchor = .bottom
            result.message = "Your result is no longer in the top 100. Try again to reach the list."
        }
        return result
    }
}
