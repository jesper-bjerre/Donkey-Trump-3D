import Foundation
import Testing
@testable import DonkeyTrump3D

actor ManualHighscoreClock: HighscoreClock {
    private var waiters: [UUID: CheckedContinuation<Void, Error>] = [:]
    func sleepForDeadline() async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { waiters[id] = $0 }
        } onCancel: { Task { await self.cancel(id) } }
    }
    private func cancel(_ id: UUID) { waiters.removeValue(forKey: id)?.resume(throwing: CancellationError()) }
    func expire() {
        let pending = waiters; waiters.removeAll()
        for continuation in pending.values { continuation.resume() }
    }
    var pendingCount: Int { waiters.count }
}

actor ScriptedHighscoreService: HighscoreService {
    var reads = 0
    var posts: [HighscoreSubmission] = []
    let onRead: @Sendable () async throws -> HighscoreSnapshot
    let onSubmit: @Sendable (HighscoreSubmission) async throws -> HighscoreSnapshot
    init(read: @escaping @Sendable () async throws -> HighscoreSnapshot,
         submit: @escaping @Sendable (HighscoreSubmission) async throws -> HighscoreSnapshot = { _ in throw HighscoreServiceError.unconfirmed }) {
        onRead = read; onSubmit = submit
    }
    func read() async throws -> HighscoreSnapshot { reads += 1; return try await onRead() }
    func submit(_ value: HighscoreSubmission) async throws -> HighscoreSnapshot { posts.append(value); return try await onSubmit(value) }
}

/// Resolves even after cancellation to reproduce a transport returning to an obsolete screen.
actor DelayedHighscoreResponse {
    private var continuation: CheckedContinuation<HighscoreSnapshot, Error>?
    func value() async throws -> HighscoreSnapshot { try await withCheckedThrowingContinuation { continuation = $0 } }
    func resolve(_ value: HighscoreSnapshot) { continuation?.resume(returning: value); continuation = nil }
    var isWaiting: Bool { continuation != nil }
}

final class HighscoreFixturesBundle: NSObject { }
func highscoreFixtureData() throws -> Data {
    let url = try #require(Bundle(for: HighscoreFixturesBundle.self).url(forResource: "highscores", withExtension: "json"))
    return try Data(contentsOf: url)
}

@MainActor
func eventually(_ condition: @escaping @MainActor () async -> Bool) async -> Bool {
    for _ in 0..<200 {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return false
}

final class HighscoreURLProtocol: URLProtocol, @unchecked Sendable {
    static let lock = NSLock()
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); let callback = Self.handler; Self.lock.unlock()
        do {
            guard let callback else { throw URLError(.cannotConnectToHost) }
            let (response, data) = try callback(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() { }
}
