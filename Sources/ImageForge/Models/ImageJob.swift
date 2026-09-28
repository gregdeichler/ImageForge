import Foundation

struct ImageJob: Codable, Identifiable, Hashable, Sendable {
    enum Provider: String, Codable, CaseIterable, Sendable {
        case apple
        case local
        case mock
    }

    enum Status: String, Codable, CaseIterable, Sendable {
        case pending
        case ready
        case generating
        case completed
        case failed
        case skipped
    }

    let id: String
    var filename: String
    var prompt: String
    var width: Int?
    var height: Int?
    var provider: Provider = .apple
    var status: Status = .pending
    var errorMessage: String?
}
