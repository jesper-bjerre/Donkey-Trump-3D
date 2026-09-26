import Foundation

struct CompletedRun: Equatable, Sendable {
    let id: UUID
    let score: Int
    let levelReached: Int
}
