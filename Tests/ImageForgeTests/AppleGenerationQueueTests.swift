import Foundation
import Testing
@testable import ImageForge

@MainActor
@Test func cancellingAppleGenerationReturnsJobToReady() {
    let queue = BatchQueueModel()
    queue.manifest = BatchManifest(
        schemaVersion: 1,
        project: "Test",
        outputDirectory: FileManager.default.temporaryDirectory.path,
        jobs: [
            ImageJob(id: "one", filename: "one.png", prompt: "one", provider: .apple, status: .ready)
        ]
    )
    queue.selectedJobID = "one"

    queue.beginAppleGeneration(for: "one")
    #expect(queue.jobs[0].status == .generating)
    #expect(queue.isRunning)

    queue.cancelAppleGeneration(for: "one")
    #expect(queue.jobs[0].status == .ready)
    #expect(!queue.isRunning)
}

@MainActor
@Test func acceptingAppleImageSavesAndAdvances() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let temporaryImage = root.appendingPathComponent("generated.png")
    try Data("generated".utf8).write(to: temporaryImage)

    let output = root.appendingPathComponent("output", isDirectory: true)

    let queue = BatchQueueModel()
    queue.manifest = BatchManifest(
        schemaVersion: 1,
        project: "Test",
        outputDirectory: output.path,
        jobs: [
            ImageJob(id: "one", filename: "one.png", prompt: "one", provider: .apple, status: .ready),
            ImageJob(id: "two", filename: "two.png", prompt: "two", provider: .apple, status: .pending)
        ]
    )
    queue.selectedJobID = "one"

    queue.beginAppleGeneration(for: "one")
    let destination = queue.acceptAppleGeneratedImage(temporaryImage, for: "one")

    #expect(destination == output.appendingPathComponent("one.png"))
    #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("one.png").path))
    #expect(queue.jobs[0].status == .completed)
    #expect(queue.jobs[1].status == .ready)
    #expect(queue.selectedJobID == "two")
    #expect(!queue.isRunning)
}
