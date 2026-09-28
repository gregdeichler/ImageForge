import Foundation

struct BatchSession: Codable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion = currentSchemaVersion
    var manifest: BatchManifest
    var selectedJobID: String?
    var sourcePath: String?
}

enum BatchPersistenceError: LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            "Persisted batch schema version \(version) is not supported."
        }
    }
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
        let session = try JSONDecoder().decode(BatchSession.self, from: data)
        guard session.schemaVersion == BatchSession.currentSchemaVersion else {
            throw BatchPersistenceError.unsupportedSchemaVersion(session.schemaVersion)
        }
        try session.manifest.validate()
        return session
    }

    func save(_ session: BatchSession) throws {
        let directory = stateURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(session)
        try data.write(to: stateURL, options: .atomic)
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: stateURL.path) else { return }
        try FileManager.default.removeItem(at: stateURL)
    }
}
