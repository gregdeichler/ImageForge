import Foundation

struct BatchManifest: Codable, Sendable {
    static let currentSchemaVersion = 2
    static let supportedSchemaVersions = 1...currentSchemaVersion

    var schemaVersion: Int
    var project: String
    var outputDirectory: String
    var jobs: [ImageJob]

    static func load(from url: URL) throws -> BatchManifest {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let manifest = try decoder.decode(BatchManifest.self, from: data)
        try manifest.validate()
        return manifest
    }

    func validate() throws {
        guard Self.supportedSchemaVersions.contains(schemaVersion) else {
            throw BatchManifestValidationError.unsupportedSchemaVersion(schemaVersion)
        }

        guard !project.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BatchManifestValidationError.emptyProject
        }

        guard !outputDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BatchManifestValidationError.emptyOutputDirectory
        }

        guard !jobs.isEmpty else {
            throw BatchManifestValidationError.noJobs
        }

        var ids = Set<String>()
        var filenames = Set<String>()

        for job in jobs {
            let trimmedID = job.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedID.isEmpty else {
                throw BatchManifestValidationError.invalidJob(job.id, "Job id must not be empty.")
            }
            guard ids.insert(trimmedID).inserted else {
                throw BatchManifestValidationError.duplicateJobID(trimmedID)
            }

            let filename = job.filename.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else {
                throw BatchManifestValidationError.invalidJob(job.id, "Filename must not be empty.")
            }
            guard filename == NSString(string: filename).lastPathComponent,
                  !filename.contains("/"),
                  !filename.contains("\\") else {
                throw BatchManifestValidationError.invalidJob(
                    job.id,
                    "Filename must be a filename only, not a path."
                )
            }

            let filenameKey = filename.lowercased()
            guard filenames.insert(filenameKey).inserted else {
                throw BatchManifestValidationError.duplicateFilename(filename)
            }

            if job.provider != .mock {
                let ext = NSString(string: filename).pathExtension.lowercased()
                guard OutputWriter.supportedImageExtensions.contains(ext) else {
                    throw BatchManifestValidationError.invalidJob(
                        job.id,
                        "Unsupported image output format '.\(ext)'. Use PNG, JPEG, HEIC/HEIF, or TIFF."
                    )
                }
            }

            guard !job.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BatchManifestValidationError.invalidJob(job.id, "Prompt must not be empty.")
            }

            if (job.width == nil) != (job.height == nil) {
                throw BatchManifestValidationError.invalidJob(
                    job.id,
                    "Width and height must either both be present or both be omitted."
                )
            }

            if let width = job.width, width <= 0 {
                throw BatchManifestValidationError.invalidJob(job.id, "Width must be greater than zero.")
            }

            if let height = job.height, height <= 0 {
                throw BatchManifestValidationError.invalidJob(job.id, "Height must be greater than zero.")
            }

            if let referenceImage = job.referenceImage,
               referenceImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw BatchManifestValidationError.invalidJob(
                    job.id,
                    "referenceImage must not be blank when supplied."
                )
            }
        }
    }
}

enum BatchManifestValidationError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case emptyProject
    case emptyOutputDirectory
    case noJobs
    case duplicateJobID(String)
    case duplicateFilename(String)
    case invalidJob(String, String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            "Manifest schema version \(version) is not supported. ImageForge supports versions 1 through \(BatchManifest.currentSchemaVersion)."
        case .emptyProject:
            "Manifest project must not be empty."
        case .emptyOutputDirectory:
            "Manifest outputDirectory must not be empty."
        case .noJobs:
            "Manifest must contain at least one image job."
        case .duplicateJobID(let id):
            "Manifest contains duplicate job id '\(id)'."
        case .duplicateFilename(let filename):
            "Manifest contains duplicate output filename '\(filename)'."
        case .invalidJob(let id, let reason):
            "Image job '\(id)' is invalid: \(reason)"
        }
    }
}
