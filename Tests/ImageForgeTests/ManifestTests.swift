import Foundation
import Testing
@testable import ImageForge

@Test func decodesLegacyManifestWithDefaults() throws {
    let json = #"{"schemaVersion":1,"project":"Test","outputDirectory":"~/Pictures/Test","jobs":[{"id":"one","filename":"one.png","prompt":"hello"}]}"#
    let manifest = try JSONDecoder().decode(BatchManifest.self, from: Data(json.utf8))

    #expect(manifest.project == "Test")
    #expect(manifest.jobs.count == 1)
    #expect(manifest.jobs[0].provider == .apple)
    #expect(manifest.jobs[0].status == .pending)
    #expect(manifest.jobs[0].tags.isEmpty)
}

@Test func validatesProductionMetadataAndGenerationPrompt() throws {
    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "AFF",
        outputDirectory: "~/Pictures/AFF",
        jobs: [
            ImageJob(
                id: "philadelphia-independence-primary",
                filename: "philadelphia-independence-primary.png",
                prompt: "Broken bell.",
                team: "Philadelphia Independence",
                assetType: "logo",
                variant: "primary-full-color",
                negativePrompt: "text, mockup",
                referenceImage: "references/philadelphia.png",
                tags: ["aff", "federal-east"],
                width: 2048,
                height: 2048
            )
        ]
    )

    try manifest.validate()

    #expect(manifest.jobs[0].generationPrompt.contains("Avoid: text, mockup"))
    #expect(manifest.jobs[0].team == "Philadelphia Independence")
}

@Test func rejectsDuplicateJobIDsAndFilenames() {
    let duplicateIDs = BatchManifest(
        schemaVersion: 2,
        project: "Test",
        outputDirectory: "/tmp",
        jobs: [
            ImageJob(id: "same", filename: "one.png", prompt: "one"),
            ImageJob(id: "same", filename: "two.png", prompt: "two")
        ]
    )

    var duplicateIDThrew = false
    do {
        try duplicateIDs.validate()
    } catch {
        duplicateIDThrew = true
    }
    #expect(duplicateIDThrew)

    let duplicateFilenames = BatchManifest(
        schemaVersion: 2,
        project: "Test",
        outputDirectory: "/tmp",
        jobs: [
            ImageJob(id: "one", filename: "Logo.png", prompt: "one"),
            ImageJob(id: "two", filename: "logo.png", prompt: "two")
        ]
    )

    var duplicateFilenameThrew = false
    do {
        try duplicateFilenames.validate()
    } catch {
        duplicateFilenameThrew = true
    }
    #expect(duplicateFilenameThrew)
}

@Test func rejectsUnsafeFilenameAndPartialDimensions() {
    let unsafe = BatchManifest(
        schemaVersion: 2,
        project: "Test",
        outputDirectory: "/tmp",
        jobs: [
            ImageJob(id: "one", filename: "../escape.png", prompt: "one")
        ]
    )

    var unsafeThrew = false
    do {
        try unsafe.validate()
    } catch {
        unsafeThrew = true
    }
    #expect(unsafeThrew)

    let partialSize = BatchManifest(
        schemaVersion: 2,
        project: "Test",
        outputDirectory: "/tmp",
        jobs: [
            ImageJob(id: "one", filename: "one.png", prompt: "one", width: 1024)
        ]
    )

    var partialSizeThrew = false
    do {
        try partialSize.validate()
    } catch {
        partialSizeThrew = true
    }
    #expect(partialSizeThrew)
}


@Test func rejectsUnsupportedImageOutputExtension() {
    let manifest = BatchManifest(
        schemaVersion: 2,
        project: "Formats",
        outputDirectory: "/tmp",
        jobs: [
            ImageJob(
                id: "one",
                filename: "one.webp",
                prompt: "one",
                provider: .apple
            )
        ]
    )

    #expect(throws: BatchManifestValidationError.self) {
        try manifest.validate()
    }
}
