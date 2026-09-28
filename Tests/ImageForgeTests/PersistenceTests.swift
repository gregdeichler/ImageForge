import Foundation
import Testing
@testable import ImageForge

@MainActor
@Test func restoresPersistedProgressAndResetsInterruptedGeneration() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgePersistenceTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let stateURL = root.appendingPathComponent("current-batch.json")
    let store = BatchPersistenceStore(stateURL: stateURL)

    let session = BatchSession(
        manifest: BatchManifest(
            schemaVersion: 1,
            project: "Persisted",
            outputDirectory: root.path,
            jobs: [
                ImageJob(id: "one", filename: "one.png", prompt: "one", provider: .apple, status: .completed),
                ImageJob(id: "two", filename: "two.png", prompt: "two", provider: .apple, status: .generating)
            ]
        ),
        selectedJobID: "two",
        sourcePath: "/tmp/source.json"
    )
    try store.save(session)

    let queue = BatchQueueModel(persistenceStore: store)

    #expect(queue.manifest?.project == "Persisted")
    #expect(queue.jobs[0].status == .completed)
    #expect(queue.jobs[1].status == .ready)
    #expect(queue.selectedJobID == "two")
}

@MainActor
@Test func clearBatchRemovesPersistedSession() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageForgePersistenceTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let stateURL = root.appendingPathComponent("current-batch.json")
    let store = BatchPersistenceStore(stateURL: stateURL)
    let queue = BatchQueueModel(persistenceStore: store)

    queue.manifest = BatchManifest(
        schemaVersion: 1,
        project: "Persisted",
        outputDirectory: root.path,
        jobs: []
    )
    try store.save(BatchSession(manifest: queue.manifest!, selectedJobID: nil, sourcePath: nil))
    #expect(FileManager.default.fileExists(atPath: stateURL.path))

    queue.clearBatch()

    #expect(queue.manifest == nil)
    #expect(!FileManager.default.fileExists(atPath: stateURL.path))
}
