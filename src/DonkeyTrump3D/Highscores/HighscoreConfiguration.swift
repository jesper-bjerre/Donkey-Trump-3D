import Foundation

struct HighscoreConfiguration: Sendable {
    let baseURL: URL
    let isLocalIntegration: Bool
    var endpoint: URL { baseURL.appendingPathComponent("api/v1/highscores") }

    init(baseURL: URL) throws {
        guard baseURL.scheme == "https", let host = baseURL.host, !host.isEmpty,
              baseURL.user == nil, baseURL.password == nil, baseURL.query == nil, baseURL.fragment == nil else {
            throw HighscoreServiceError.unavailable
        }
        self.baseURL = baseURL; isLocalIntegration = false
    }
    #if DEBUG
    init(localOrigin: URL) throws {
        guard localOrigin.scheme == "http", ["localhost", "127.0.0.1", "[::1]", "::1"].contains(localOrigin.host ?? ""),
              localOrigin.user == nil, localOrigin.password == nil, localOrigin.query == nil, localOrigin.fragment == nil,
              localOrigin.path.isEmpty || localOrigin.path == "/" else { throw HighscoreServiceError.unavailable }
        baseURL = localOrigin; isLocalIntegration = true
    }
    #endif

    static func bundled(_ bundle: Bundle = .main) -> Self? {
        guard let text = bundle.object(forInfoDictionaryKey: "HighscoreAPIBaseURL") as? String,
              !text.isEmpty, let url = URL(string: text) else { return nil }
        #if DEBUG
        if url.scheme == "http" { return try? Self(localOrigin: url) }
        #endif
        return try? Self(baseURL: url)
    }
}
