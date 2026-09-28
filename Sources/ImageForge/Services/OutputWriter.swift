import Foundation

struct OutputWriter {
    func save(_ generated: GeneratedImage, for job: ImageJob, manifest: BatchManifest) throws -> URL {
        let expanded = NSString(string: manifest.outputDirectory).expandingTildeInPath
        let directory = URL(fileURLWithPath: expanded, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent(job.filename)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: generated.temporaryURL, to: destination)
        return destination
    }
}
