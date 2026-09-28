#if DEBUG
import Foundation

/// Compiled out of Release. Synthetic runs never select the production service.
enum HighscoreFixtureLaunch {
    case fixture(String)
    case integration(URL)
    case unavailable

    static func parse(_ args: [String]) -> Self? {
        func value(_ key: String) -> String? {
            guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if args.contains("-highscoreIntegration") {
            guard let raw = value("-highscoreLocalOrigin"), let url = URL(string: raw),
                  url.scheme == "http", ["localhost", "127.0.0.1", "[::1]", "::1"].contains(url.host ?? ""),
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
                  url.path.isEmpty || url.path == "/" else { return .unavailable }
            return .integration(url)
        }
        if let fixture = value("-highscoreFixture") { return .fixture(fixture) }
        if args.contains("-highscoreUITest") { return .unavailable }
        return nil
    }

    static func run(for name: String, id: UUID = UUID()) -> CompletedRun {
        let score: Int
        switch name {
        case "rank-1": score = 20_200
        case "rank-50", "duplicate-names": score = 10_300
        case "rank-100", "cutoff-race": score = 300
        case "below-cutoff": score = 0
        case "equal-cutoff": score = 200
        default: score = 1_200
        }
        return CompletedRun(id: id, score: score, levelReached: 2)
    }
}

actor HighscoreFixtureService: HighscoreService {
    let fixture: String
    private var snapshot: HighscoreSnapshot
    private var reads = 0
    private var posts = 0
    private let recordCounters: Bool
    init(_ fixture: String, recordCounters: Bool = false) {
        self.fixture = fixture; self.recordCounters = recordCounters
        snapshot = Self.prepared(count: ["empty", "validation-error", "offline-first"].contains(fixture) ? 0 : 100)
    }
    static func prepared(count: Int) -> HighscoreSnapshot {
        .init(entries: (0..<count).map { index in
            HighscoreEntry(entryId: UUID(uuidString: String(format: "10000000-0000-0000-0000-%012d", index + 1))!, rank: index + 1,
                           displayName: index < 2 ? "Duplicate" : "Player \(index + 1)", score: (100 - index) * 200)
        }, revision: count == 0 ? "empty" : "fixture", fetchedAtUtc: Date())
    }
    func requestCounts() -> (reads: Int, posts: Int) { (reads, posts) }
    private func count(_ key: String) {
        guard recordCounters else { return }
        let defaults = UserDefaults.standard
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }
    func read() async throws -> HighscoreSnapshot {
        reads += 1; count("highscoreFixtureReads")
        if fixture == "offline-first" && reads == 1 { throw HighscoreServiceError.unavailable }
        if fixture == "refresh-fails" && reads > 1 { throw HighscoreServiceError.unavailable }
        switch fixture {
        case "unavailable": throw HighscoreServiceError.unavailable
        case "hang", "slow-stream": try await Task.sleep(for: .seconds(60))
        case "late-response":
            // Intentionally ignores cancellation, exercising the coordinator's generation guard.
            await withCheckedContinuation { continuation in
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) { continuation.resume() }
            }
        default: break
        }
        return snapshot
    }
    func submit(_ submission: HighscoreSubmission) async throws -> HighscoreSnapshot {
        posts += 1; count("highscoreFixturePosts")
        if fixture == "save-ack-lost" { throw HighscoreServiceError.unconfirmed }
        if fixture == "validation-error" && posts == 1 {
            throw HighscoreServiceError.rejected(HighscoreProblem(type: "about:blank", title: "Invalid highscore submission", status: 422,
                                                                code: "name_rejected", errors: ["displayName": ["Enter another name."]]))
        }
        if fixture == "cutoff-race" || !snapshot.qualifies(submission.score) {
            let newer = Self.prepared(count: 100)
            let entries = newer.entries.map { entry in
                HighscoreEntry(entryId: entry.id, rank: entry.rank, displayName: entry.displayName,
                               score: entry.score + (fixture == "cutoff-race" ? 200 : 0))
            }
            return .init(entries: entries, revision: "changed", fetchedAtUtc: Date(), outcome: .notQualified)
        }
        var entries = snapshot.entries
        entries.append(.init(entryId: submission.submissionId, rank: 0, displayName: submission.displayName, score: submission.score))
        entries = entries.enumerated().sorted { a, b in a.element.score == b.element.score ? a.offset < b.offset : a.element.score > b.element.score }
            .prefix(100).enumerated().map { index, item in
                .init(entryId: item.element.id, rank: index + 1, displayName: item.element.displayName, score: item.element.score)
            }
        snapshot = .init(entries: entries, revision: "saved", fetchedAtUtc: Date())
        return .init(entries: entries, revision: "saved", fetchedAtUtc: Date(), outcome: .ranked,
                     entryId: submission.submissionId, rank: entries.first(where: { $0.id == submission.submissionId })?.rank)
    }
}
#endif
