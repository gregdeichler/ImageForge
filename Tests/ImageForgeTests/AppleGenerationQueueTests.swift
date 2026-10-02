import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import ImageForge

@MainActor
private func makeQueue(in root: URL) -> BatchQueueModel {
    let stateURL = root.appendingPathComponent("session.json")
    return BatchQueueModel(persistenceStore: BatchPersistenceStore(stateURL: stateURL))
}

@MainActor
@Test func cancellingAppleGenerationReturnsJobToReady() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let queue = makeQueue(in: root)
    queue.manifest = BatchManifest(
        schemaVersion: 1,
        project: "Test",
        outputDirectory: root.path,
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
    try writeOnePixelPNG(to: temporaryImage)

    let output = root.appendingPathComponent("output", isDirectory: true)

    let queue = makeQueue(in: root)
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

@MainActor
@Test func loadingManifestSelectsFirstActionableJobNotCompletedJob() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeManifestSelection-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let manifestURL = root.appendingPathComponent("batch.json")
    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Selection",
        outputDirectory: root.path,
        jobs: [
            ImageJob(id: "done", filename: "done.png", prompt: "done", status: .completed),
            ImageJob(id: "next", filename: "next.png", prompt: "next", status: .pending)
        ]
    )
    let data = try JSONEncoder().encode(manifest)
    try data.write(to: manifestURL)

    let queue = makeQueue(in: root)
    try queue.loadManifest(from: manifestURL)

    #expect(queue.selectedJobID == "next")
    #expect(queue.jobs[1].status == .ready)
}

@MainActor
@Test func resolvesRelativeReferenceImageBesideManifest() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeReference-\(UUID().uuidString)", isDirectory: true)
    let references = root.appendingPathComponent("references", isDirectory: true)
    try FileManager.default.createDirectory(at: references, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let manifestURL = root.appendingPathComponent("batch.json")
    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Reference",
        outputDirectory: root.path,
        jobs: [
            ImageJob(
                id: "one",
                filename: "one.png",
                prompt: "one",
                referenceImage: "references/master.png"
            )
        ]
    )
    try JSONEncoder().encode(manifest).write(to: manifestURL)

    let queue = makeQueue(in: root)
    try queue.loadManifest(from: manifestURL)

    #expect(queue.referenceImageURL(for: queue.jobs[0]) == references.appendingPathComponent("master.png"))
}

private func writeOnePixelPNG(to url: URL) throws {
    var pixel: [UInt8] = [255, 0, 0, 255]
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let context = CGContext(
        data: &pixel,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ),
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw TestImageError.creationFailed
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw TestImageError.creationFailed
    }
}

private enum TestImageError: Error {
    case creationFailed
}


@MainActor
@Test func finishedProgressIncludesSkippedJobs() {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeProgress-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let queue = makeQueue(in: root)
    queue.manifest = BatchManifest(
        schemaVersion: 2,
        project: "Progress",
        outputDirectory: root.path,
        jobs: [
            ImageJob(id: "done", filename: "done.png", prompt: "done", status: .completed),
            ImageJob(id: "skip", filename: "skip.png", prompt: "skip", status: .skipped),
            ImageJob(id: "next", filename: "next.png", prompt: "next", status: .ready)
        ]
    )

    #expect(queue.completedCount == 1)
    #expect(queue.skippedCount == 1)
    #expect(queue.finishedCount == 2)
}
