import Foundation

struct BatchManifest: Codable, Sendable {
    var schemaVersion: Int
    var project: String
    var outputDirectory: String
    var jobs: [ImageJob]

    static func load(from url: URL) throws -> BatchManifest {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(BatchManifest.self, from: data)
    }
}
