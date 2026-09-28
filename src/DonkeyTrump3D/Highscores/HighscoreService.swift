import Foundation

protocol HighscoreService: Sendable {
    func read() async throws -> HighscoreSnapshot
    func submit(_ submission: HighscoreSubmission) async throws -> HighscoreSnapshot
}

enum HighscoreServiceError: Error, Sendable {
    case unavailable, invalidResponse, unconfirmed, credentialUnavailable
    case rejected(HighscoreProblem)
}

struct UnavailableHighscoreService: HighscoreService {
    func read() async throws -> HighscoreSnapshot { throw HighscoreServiceError.unavailable }
    func submit(_ submission: HighscoreSubmission) async throws -> HighscoreSnapshot { throw HighscoreServiceError.unavailable }
}
