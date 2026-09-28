import Foundation

struct MockImageProvider: ImageGenerationProvider {
    let id: ImageJob.Provider = .mock

    func generate(job: ImageJob) async throws -> GeneratedImage {
        try await Task.sleep(for: .milliseconds(500))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(job.id)-mock.txt")
        try job.prompt.write(to: url, atomically: true, encoding: .utf8)
        return GeneratedImage(temporaryURL: url)
    }
}
