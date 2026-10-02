import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import ImageForge

@Test func outputWriterTranscodesProviderImageToRequestedPNG() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeOutputWriter-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let sourceURL = root.appendingPathComponent("provider-output.jpg")
    try writeOnePixelImage(to: sourceURL, type: .jpeg)

    let outputDirectory = root.appendingPathComponent("output", isDirectory: true)
    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Transcode",
        outputDirectory: outputDirectory.path,
        jobs: [
            ImageJob(
                id: "logo",
                filename: "logo.png",
                prompt: "logo",
                provider: .apple,
                status: .ready
            )
        ]
    )

    let destination = try OutputWriter().save(
        GeneratedImage(temporaryURL: sourceURL),
        for: manifest.jobs[0],
        manifest: manifest
    )

    let source = CGImageSourceCreateWithURL(destination as CFURL, nil)
    #expect(source != nil)
    #expect(CGImageSourceGetType(source!) as String? == UTType.png.identifier)

    let signature = try Data(contentsOf: destination).prefix(8)
    #expect(Array(signature) == [137, 80, 78, 71, 13, 10, 26, 10])
}

@Test func outputWriterPreservesMockNonImageOutput() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeOutputWriterMock-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let sourceURL = root.appendingPathComponent("mock.txt")
    try Data("mock".utf8).write(to: sourceURL)

    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Mock",
        outputDirectory: root.path,
        jobs: [
            ImageJob(
                id: "mock",
                filename: "mock.png",
                prompt: "mock",
                provider: .mock,
                status: .ready
            )
        ]
    )

    let destination = try OutputWriter().save(
        GeneratedImage(temporaryURL: sourceURL),
        for: manifest.jobs[0],
        manifest: manifest
    )

    #expect(try String(contentsOf: destination, encoding: .utf8) == "mock")
}

private func writeOnePixelImage(to url: URL, type: UTType) throws {
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
        type.identifier as CFString,
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


@Test func outputWriterPreservesExistingDestinationWhenEncodingFails() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgeAtomicWriter-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let destination = root.appendingPathComponent("logo.png")
    let original = Data("known-good-output".utf8)
    try original.write(to: destination)

    let invalidSource = root.appendingPathComponent("invalid-image.bin")
    try Data("not-an-image".utf8).write(to: invalidSource)

    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Atomic",
        outputDirectory: root.path,
        jobs: [
            ImageJob(
                id: "logo",
                filename: "logo.png",
                prompt: "logo",
                provider: .apple,
                status: .ready
            )
        ]
    )

    #expect(throws: OutputWriterError.self) {
        try OutputWriter().save(
            GeneratedImage(temporaryURL: invalidSource),
            for: manifest.jobs[0],
            manifest: manifest
        )
    }

    #expect(try Data(contentsOf: destination) == original)
}
