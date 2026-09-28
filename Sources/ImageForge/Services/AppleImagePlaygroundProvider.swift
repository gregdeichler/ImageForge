import Foundation

/// Descriptor for Apple's interactive Image Playground path.
///
/// The actual Image Playground sheet must be presented from SwiftUI. ImageForge therefore
/// coordinates Apple generation in ContentView/BatchQueueModel rather than pretending it
/// is an unattended ImageGenerationProvider.
struct AppleImagePlaygroundProvider: Sendable {
    let id: ImageJob.Provider = .apple
}
