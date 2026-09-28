import Foundation

struct BatchSession: Codable, Sendable {
    var schemaVersion = 1
    var manifest: BatchManifest
    var selectedJobID: String?
    var sourcePath: String?
}

struct BatchPersistenceStore: Sendable {
    let stateURL: URL

    static var live: BatchPersistenceStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageForge", isDirectory: true)
        return BatchPersistenceStore(stateURL: base.appendingPathComponent("current-batch.json"))
    }

    func load() throws -> BatchSession? {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return nil }
        let data = try Data(contentsOf: stateURL)
        return try JSONDecoder().decode(BatchSession.self, from: data)
    }

    func save(_ session: BatchSession) throws {
        let directory = stateURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(session)
        try data.write(to: stateURL, options: .atomic)
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        try FileManager.default.removeItem(at: stateURL)
    }
}
