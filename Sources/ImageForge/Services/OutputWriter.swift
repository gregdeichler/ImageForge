import Foundation
import ImageIO
import UniformTypeIdentifiers

enum OutputWriterError: LocalizedError {
    case unsafeFilename(String)
    case imageEncodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsafeFilename(let filename):
            "Refusing to write unsafe output filename '\(filename)'."
        case .imageEncodingFailed(let filename):
            "Could not encode generated image as '\(filename)'."
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

        if let destinationType = destinationType(for: destination),
           let source = CGImageSourceCreateWithURL(generated.temporaryURL as CFURL, nil) {
            guard let imageDestination = CGImageDestinationCreateWithURL(
                destination as CFURL,
                destinationType.identifier as CFString,
                1,
                nil
            ) else {
                throw OutputWriterError.imageEncodingFailed(job.filename)
            }

            // Transcode instead of merely renaming the provider's temporary file.
            // Image Playground may return JPEG/HEIF data even when the manifest filename
            // ends in .png. Copying those bytes unchanged creates a mislabeled file that
            // image uploaders and MIME sniffers can reject.
            CGImageDestinationAddImageFromSource(imageDestination, source, 0, nil)
            guard CGImageDestinationFinalize(imageDestination) else {
                throw OutputWriterError.imageEncodingFailed(job.filename)
            }
        } else {
            // Non-image providers (notably the mock provider) may intentionally return
            // arbitrary files. Preserve the existing behavior for those outputs.
            try FileManager.default.copyItem(at: generated.temporaryURL, to: destination)
        }

        return destination
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
