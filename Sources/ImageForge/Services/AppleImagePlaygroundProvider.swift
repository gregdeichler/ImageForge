import Foundation

/// Golden Gate implementation target.
///
/// This provider is deliberately isolated from the queue engine. The next implementation
/// step is to wire the current Image Playground presentation API into SwiftUI and return
/// the accepted result URL to the queue coordinator.
struct AppleImagePlaygroundProvider: ImageGenerationProvider {
    let id: ImageJob.Provider = .apple

    func generate(job: ImageJob) async throws -> GeneratedImage {
        throw ImageGenerationError.notImplemented(
            "Apple Image Playground integration is the next implementation milestone."
        )
    }
}
