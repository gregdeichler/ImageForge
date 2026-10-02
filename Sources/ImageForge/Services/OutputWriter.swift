import Foundation
import ImageIO
import UniformTypeIdentifiers

enum OutputWriterError: LocalizedError {
    case unsafeFilename(String)
    case unsupportedOutputFormat(String)
    case imageEncodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsafeFilename(let filename):
            "Refusing to write unsafe output filename '\(filename)'."
        case .unsupportedOutputFormat(let filename):
            "Unsupported image output format for '\(filename)'. Use PNG, JPEG, HEIC/HEIF, or TIFF."
        case .imageEncodingFailed(let filename):
            "Could not encode generated image as '\(filename)'."
        }
    }
}

struct OutputWriter {
    static let supportedImageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "heic", "heif", "tif", "tiff"
    ]

    func save(_ generated: GeneratedImage, for job: ImageJob, manifest: BatchManifest) throws -> URL {
        let expanded = NSString(string: manifest.outputDirectory).expandingTildeInPath
        let directory = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let destination = directory.appendingPathComponent(job.filename).standardizedFileURL
        guard destination.deletingLastPathComponent().path == directory.path else {
            throw OutputWriterError.unsafeFilename(job.filename)
        }

        let temporaryDestination = directory
            .appendingPathComponent(".imageforge-\(UUID().uuidString)-\(job.filename)")
            .standardizedFileURL

        defer {
            try? FileManager.default.removeItem(at: temporaryDestination)
        }

        if job.provider == .mock {
            try FileManager.default.copyItem(at: generated.temporaryURL, to: temporaryDestination)
        } else {
            guard let destinationType = destinationType(for: destination) else {
                throw OutputWriterError.unsupportedOutputFormat(job.filename)
            }

            guard let source = CGImageSourceCreateWithURL(generated.temporaryURL as CFURL, nil),
                  let imageDestination = CGImageDestinationCreateWithURL(
                    temporaryDestination as CFURL,
                    destinationType.identifier as CFString,
                    1,
                    nil
                  ) else {
                throw OutputWriterError.imageEncodingFailed(job.filename)
            }

            CGImageDestinationAddImageFromSource(imageDestination, source, 0, nil)
            guard CGImageDestinationFinalize(imageDestination) else {
                throw OutputWriterError.imageEncodingFailed(job.filename)
            }
        }

        try commit(temporaryDestination, to: destination)
        return destination
    }

    private func commit(_ temporaryURL: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try FileManager.default.replaceItemAt(
                destination,
                withItemAt: temporaryURL,
                backupItemName: nil,
                options: []
            )
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
        }
    }

    private func destinationType(for url: URL) -> UTType? {
        switch url.pathExtension.lowercased() {
        case "png":
            .png
        case "jpg", "jpeg":
            .jpeg
        case "heic", "heif":
            .heic
        case "tif", "tiff":
            .tiff
        default:
            nil
        }
    }
}
