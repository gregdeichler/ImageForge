import Foundation

struct GeneratedImage: Sendable {
    let temporaryURL: URL
}

/// Providers that can generate without presenting provider-owned UI.
///
/// Apple's Image Playground external-provider flow is intentionally interactive and is
/// presented from SwiftUI, so it does not conform to this protocol. Local and mock
/// providers can use this contract for unattended generation.
protocol ImageGenerationProvider: Sendable {
    var id: ImageJob.Provider { get }
    func generate(job: ImageJob) async throws -> GeneratedImage
}
