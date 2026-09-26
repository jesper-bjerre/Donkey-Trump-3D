import Foundation
import Testing
@testable import DonkeyTrump3D

@Suite("Highscore wire contract", .serialized)
struct HighscoreServiceTests {
    @Test func productionAndLocalOverridesAreSeparate() throws {
        #expect(throws: (any Error).self) { try HighscoreConfiguration(baseURL: URL(string: "http://localhost:1234")!) }
        for text in ["https://production.example", "http://localhost.evil:1234", "http://127.0.0.1:1234/path", "http://user@localhost:1234", "http://localhost:1234?fallback=https://production.example"] {
            #expect(throws: (any Error).self) { try HighscoreConfiguration(localOrigin: URL(string: text)!) }
            let selection = HighscoreFixtureLaunch.parse(["-highscoreIntegration", "-highscoreLocalOrigin", text])
            if case .unavailable = selection { } else { Issue.record("Invalid integration target did not fail closed") }
        }
        let local = try HighscoreConfiguration(localOrigin: URL(string: "http://127.0.0.1:1234")!)
        #expect(local.endpoint.absoluteString == "http://127.0.0.1:1234/api/v1/highscores")
    }
    @Test func sharedNamesAndSnapshotsMatchContract() throws {
        let data = try highscoreFixtureData()
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for item in try #require(root["names"] as? [[String: Any]]) {
            let result = HighscoreRules.name(item["input"] as! String)
            if item["valid"] as! Bool { #expect(result == item["canonical"] as? String) } else { #expect(result == nil) }
        }
        for item in try #require(root["snapshots"] as? [[String: Any]]) {
            let payload = try JSONSerialization.data(withJSONObject: item["snapshot"]!)
            if item["valid"] as! Bool { #expect(throws: Never.self) { try HighscoreSnapshot.decode(payload) } }
            else { #expect(throws: (any Error).self) { try HighscoreSnapshot.decode(payload) } }
        }
    }
    @Test func rankedResponseMustIdentifyExactRow() throws {
        let json = """
        {"entries":[],"revision":"r","fetchedAtUtc":"2026-09-26T12:00:00.000Z","outcome":"ranked","entryId":"10000000-0000-0000-0000-000000000001","rank":1}
        """
        #expect(throws: (any Error).self) { try HighscoreSnapshot.decode(Data(json.utf8), submission: true) }
    }
    @Test func contradictoryNonqualificationIsAnUnconfirmedSave() async throws {
        let run = CompletedRun(id: UUID(), score: 200, levelReached: 1)
        let rows = HighscoreFixtureService.prepared(count: 100).entries.map { row in
            ["entryId": row.rank == 100 ? run.id.uuidString : row.id.uuidString,
             "rank": row.rank, "displayName": row.rank == 100 ? "Test" : row.displayName, "score": row.score] as [String: Any]
        }
        let data = try JSONSerialization.data(withJSONObject: ["entries": rows, "revision": "contradictory",
            "fetchedAtUtc": "2026-09-26T12:00:00.000Z", "outcome": "notQualified"])
        let configuration = URLSessionConfiguration.ephemeral; configuration.protocolClasses = [HighscoreURLProtocol.self]
        HighscoreURLProtocol.lock.withLock {
            HighscoreURLProtocol.handler = { request in
                (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!, data)
            }
        }
        let service = URLSessionHighscoreService(configuration: try HighscoreConfiguration(baseURL: URL(string: "https://example.invalid")!), sessionConfiguration: configuration)
        do { _ = try await service.submit(HighscoreSubmission(run: run, name: "Test")); Issue.record("Contradictory saved row must not be reported as nonqualifying") }
        catch HighscoreServiceError.unconfirmed { }
        catch { Issue.record("Wrong failure: \(error)") }
    }
    @Test func malformedSaveIsUnconfirmedAndNeverRetried() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HighscoreURLProtocol.self]
        HighscoreURLProtocol.lock.withLock {
        HighscoreURLProtocol.handler = { request in (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/json"])!, Data("{}".utf8)) }
        }
        let service = URLSessionHighscoreService(configuration: try HighscoreConfiguration(baseURL: URL(string: "https://example.invalid")!), sessionConfiguration: configuration)
        do { _ = try await service.submit(HighscoreSubmission(run: .init(id: UUID(), score: 0, levelReached: 1), name: "A")); Issue.record("Expected unconfirmed error") }
        catch HighscoreServiceError.unconfirmed { }
        catch { Issue.record("Wrong save failure: \(error)") }
    }
}
