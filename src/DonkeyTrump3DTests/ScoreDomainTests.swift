import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Five-point score domain")
struct ScoreDomainTests {
    @Test func exactEncodingMixedSnapshotsAndBounds() throws {
        for score in [0, 5, 10, 1005, 2600, 2_147_483_600] {
            let run = CompletedRun(id: UUID(), score: score, levelReached: 1)
            let encoded = try JSONEncoder().encode(HighscoreSubmission(run: run, name: "Exact"))
            let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            #expect((object["score"] as? Int) == score)
            let snapshot = HighscoreSnapshot(entries: [.init(entryId: run.id, rank: 1, displayName: "Exact", score: score)], revision: "r", fetchedAtUtc: Date())
            try snapshot.validate()
            #expect(snapshot.qualifies(score))
        }
        for score in [-5, 1, 1001, 2_147_483_605] { #expect(!HighscoreRules.validScore(score)) }
        let root = try #require(JSONSerialization.jsonObject(with: highscoreFixtureData()) as? [String: Any])
        let cases = try #require(root["snapshots"] as? [[String: Any]])
        let mixed = try #require(cases.first { $0["id"] as? String == "mixed-five-point-history" })
        let snapshot = try HighscoreSnapshot.decode(JSONSerialization.data(withJSONObject: mixed["snapshot"]!))
        #expect(snapshot.entries.map(\.score) == [2600, 1005, 1000, 10, 0])
    }
    @Test @MainActor func aboveRemoteCeilingStaysExactAndDoesNotReadOrPost() async {
        let service = HighscoreFixtureService("empty")
        let c = HighscoreCoordinator(service: service)
        let run = CompletedRun(id: UUID(), score: 2_147_483_605, levelReached: 1)
        c.complete(run)
        #expect(run.score == 2_147_483_605)
        #expect(await service.requestCounts().reads == 0)
        #expect(await service.requestCounts().posts == 0)
    }
}
