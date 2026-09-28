import Foundation

struct GeneratedImage: Sendable {
    let temporaryURL: URL
}

protocol ImageGenerationProvider: Sendable {
    var id: ImageJob.Provider { get }
    func generate(job: ImageJob) async throws -> GeneratedImage
}

enum ImageGenerationError: LocalizedError {
    case notImplemented(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented(let message): message
        }
    }
}
