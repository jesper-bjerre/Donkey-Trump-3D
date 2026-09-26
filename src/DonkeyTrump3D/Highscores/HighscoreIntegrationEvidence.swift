#if DEBUG
import Foundation

@MainActor enum HighscoreIntegrationEvidence {
    static func save(_ snapshot: HighscoreSnapshot) {
        guard case .integration = HighscoreFixtureLaunch.parse(ProcessInfo.processInfo.arguments) else { return }
        let document: [String: Any] = ["revision": snapshot.revision, "entries": snapshot.entries.map {
            ["entryId": $0.id.uuidString.lowercased(), "rank": $0.rank, "displayName": $0.displayName, "score": $0.score] as [String: Any]
        }]
        guard let data = try? JSONSerialization.data(withJSONObject: document, options: [.sortedKeys]) else { return }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? data.write(to: directory.appendingPathComponent("highscore-integration-snapshot.json"), options: .atomic)
    }
}
#endif
