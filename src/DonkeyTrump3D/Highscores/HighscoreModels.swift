import Foundation

enum HighscoreRules {
    static let zeroID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    static func validScore(_ score: Int) -> Bool { score >= 0 && score <= 2_147_483_600 && score % 100 == 0 }
    static func name(_ input: String) -> String? {
        guard !input.unicodeScalars.contains(where: {
            [.control, .lineSeparator, .paragraphSeparator].contains($0.properties.generalCategory)
        }) else { return nil }
        let name = input.precomposedStringWithCanonicalMapping.trimmingCharacters(in: .init(charactersIn: "\u{0020}\u{00a0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200a}\u{202f}\u{205f}\u{3000}"))
        guard (1...20).contains(name.count), name.utf8.count <= 256,
              name.unicodeScalars.contains(where: { !$0.properties.isWhitespace && $0.properties.generalCategory != .format }) else { return nil }
        return name
    }
}

struct HighscoreSubmission: Codable, Sendable, Equatable {
    let submissionId: UUID
    let displayName: String
    let score: Int
    let levelReached: Int

    init(run: CompletedRun, name: String) throws {
        guard run.id != HighscoreRules.zeroID, HighscoreRules.validScore(run.score),
              (1...2_147_483_647).contains(run.levelReached), let name = HighscoreRules.name(name) else {
            throw HighscoreServiceError.invalidResponse
        }
        submissionId = run.id; displayName = name; score = run.score; levelReached = run.levelReached
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(submissionId.uuidString.lowercased(), forKey: .submissionId)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(score, forKey: .score)
        try c.encode(levelReached, forKey: .levelReached)
    }
}

struct HighscoreEntry: Codable, Sendable, Equatable, Identifiable {
    let entryId: UUID
    let rank: Int
    let displayName: String
    let score: Int
    var id: UUID { entryId }
}

enum HighscoreOutcome: String, Codable, Sendable { case ranked, notQualified }

struct HighscoreSnapshot: Codable, Sendable, Equatable {
    let entries: [HighscoreEntry]
    let revision: String
    let fetchedAtUtc: Date
    var outcome: HighscoreOutcome?
    var entryId: UUID?
    var rank: Int?

    func validate(submission: Bool = false) throws {
        guard entries.count <= 100, !revision.isEmpty, revision.count <= 256,
              Set(entries.map(\.id)).count == entries.count else { throw HighscoreServiceError.invalidResponse }
        var previousScore = Int.max
        for (index, entry) in entries.enumerated() {
            guard entry.id != HighscoreRules.zeroID, entry.rank == index + 1,
                  HighscoreRules.validScore(entry.score), entry.score <= previousScore,
                  HighscoreRules.name(entry.displayName) == entry.displayName else { throw HighscoreServiceError.invalidResponse }
            previousScore = entry.score
        }
        if submission {
            switch outcome {
            case .ranked:
                guard let entryId, let rank, entries.contains(where: { $0.id == entryId && $0.rank == rank }) else { throw HighscoreServiceError.invalidResponse }
            case .notQualified:
                guard entries.count == 100, entryId == nil, rank == nil else { throw HighscoreServiceError.invalidResponse }
            case nil: throw HighscoreServiceError.invalidResponse
            }
        } else if outcome != nil || entryId != nil || rank != nil { throw HighscoreServiceError.invalidResponse }
    }

    func qualifies(_ score: Int) -> Bool {
        HighscoreRules.validScore(score) && (entries.count < 100 || score > (entries.last?.score ?? Int.max))
    }
    static func decode(_ data: Data, submission: Bool = false) throws -> Self {
        let result = try decoder().decode(Self.self, from: data)
        try result.validate(submission: submission)
        return result
    }
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard value.hasSuffix("Z"), let date = formatter.date(from: value) else { throw HighscoreServiceError.invalidResponse }
            return date
        }
        return decoder
    }
}

struct HighscoreProblem: Decodable, Error, Sendable, Equatable {
    let type: String
    let title: String
    let status: Int
    let code: String
    let errors: [String: [String]]?
    var editableNameError: Bool {
        status == 422 && code == "name_rejected"
    }
}
