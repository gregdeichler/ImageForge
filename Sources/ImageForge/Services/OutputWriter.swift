import Foundation

enum OutputWriterError: LocalizedError {
    case unsafeFilename(String)

    var errorDescription: String? {
        switch self {
        case .unsafeFilename(let filename):
            "Refusing to write unsafe output filename '\(filename)'."
        }
    }
}

struct OutputWriter {
    func save(_ generated: GeneratedImage, for job: ImageJob, manifest: BatchManifest) throws -> URL {
        let expanded = NSString(string: manifest.outputDirectory).expandingTildeInPath
        let directory = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent(job.filename).standardizedFileURL
        guard destination.deletingLastPathComponent().path == directory.path else {
            throw OutputWriterError.unsafeFilename(job.filename)
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: generated.temporaryURL, to: destination)
        return destination
    }
}
