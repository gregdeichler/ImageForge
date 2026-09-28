import Foundation
import Observation

@MainActor
@Observable
final class BatchQueueModel {
    var manifest: BatchManifest?
    var selectedJobID: String?
    var isRunning = false
    var lastError: String?

    private let outputWriter = OutputWriter()
    private let persistenceStore: BatchPersistenceStore
    private var sourcePath: String?

    init(persistenceStore: BatchPersistenceStore = .live) {
        self.persistenceStore = persistenceStore
        restorePersistedSession()
    }

    var jobs: [ImageJob] { manifest?.jobs ?? [] }

    var completedCount: Int {
        jobs.filter { $0.status == .completed }.count
    }

    var currentJob: ImageJob? {
        if let selectedJobID,
           let selected = jobs.first(where: { $0.id == selectedJobID }) {
            return selected
        }
        return jobs.first(where: isActionable)
    }

    func canGenerate(_ job: ImageJob) -> Bool {
        !isRunning && isActionable(job)
    }

    func canSkip(_ job: ImageJob) -> Bool {
        !isRunning && isActionable(job)
    }

    func referenceImageURL(for job: ImageJob) -> URL? {
        guard let rawPath = job.referenceImage?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawPath.isEmpty else {
            return nil
        }

        let expanded = NSString(string: rawPath).expandingTildeInPath
        if expanded.hasPrefix("/") {
            return URL(fileURLWithPath: expanded).standardizedFileURL
        }

        guard let sourcePath else { return nil }
        let manifestDirectory = URL(fileURLWithPath: sourcePath)
            .deletingLastPathComponent()
        return manifestDirectory
            .appendingPathComponent(rawPath)
            .standardizedFileURL
    }

    func loadManifest(from url: URL) throws {
        var loaded = try BatchManifest.load(from: url)

        // Imported manifests are declarative. A stale "generating" state cannot be resumed.
        for index in loaded.jobs.indices where loaded.jobs[index].status == .generating {
            loaded.jobs[index].status = .ready
        }

        if let first = loaded.jobs.firstIndex(where: isActionable) {
            if loaded.jobs[first].status == .pending {
                loaded.jobs[first].status = .ready
            }
            selectedJobID = loaded.jobs[first].id
        } else {
            selectedJobID = nil
        }

        manifest = loaded
        sourcePath = url.path
        lastError = nil
        persist()
    }

    func clearBatch() {
        manifest = nil
        selectedJobID = nil
        sourcePath = nil
        isRunning = false
        lastError = nil
        try? persistenceStore.clear()
    }

    func skipSelected() {
        guard let selectedJobID,
              let index = manifest?.jobs.firstIndex(where: { $0.id == selectedJobID }),
              let job = manifest?.jobs[index],
              isActionable(job) else { return }

        manifest?.jobs[index].status = .skipped
        manifest?.jobs[index].errorMessage = nil
        advanceSelection(after: index)
    }

    func beginAppleGeneration(for jobID: String) {
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }),
              let job = manifest?.jobs[index],
              job.provider == .apple,
              isActionable(job) else { return }

        manifest?.jobs[index].status = .generating
        manifest?.jobs[index].errorMessage = nil
        lastError = nil
        isRunning = true
        persist()
    }

    @discardableResult
    func acceptAppleGeneratedImage(_ temporaryURL: URL, for jobID: String) -> URL? {
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }),
              manifest?.jobs[index].status == .generating,
              let manifest else { return nil }

        do {
            let job = manifest.jobs[index]
            let destination = try outputWriter.save(
                GeneratedImage(temporaryURL: temporaryURL),
                for: job,
                manifest: manifest
            )
            self.manifest?.jobs[index].status = .completed
            self.manifest?.jobs[index].errorMessage = nil
            isRunning = false
            advanceSelection(after: index)
            return destination
        } catch {
            self.manifest?.jobs[index].status = .failed
            self.manifest?.jobs[index].errorMessage = error.localizedDescription
            lastError = error.localizedDescription
            isRunning = false
            persist()
            return nil
        }
    }

    func cancelAppleGeneration(for jobID: String) {
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }),
              manifest?.jobs[index].status == .generating else { return }

        manifest?.jobs[index].status = .ready
        isRunning = false
        persist()
    }

    func generateSelectedWithMockProvider() async {
        guard let selectedJobID,
              let index = manifest?.jobs.firstIndex(where: { $0.id == selectedJobID }),
              let selected = manifest?.jobs[index],
              isActionable(selected),
              let manifest else { return }

        isRunning = true
        self.manifest?.jobs[index].status = .generating
        persist()
        defer { isRunning = false }

        do {
            let job = manifest.jobs[index]
            let generated = try await MockImageProvider().generate(job: job)
            _ = try outputWriter.save(generated, for: job, manifest: manifest)
            self.manifest?.jobs[index].status = .completed
            self.manifest?.jobs[index].errorMessage = nil
            advanceSelection(after: index)
        } catch {
            self.manifest?.jobs[index].status = .failed
            self.manifest?.jobs[index].errorMessage = error.localizedDescription
            lastError = error.localizedDescription
            persist()
        }
    }

    private func restorePersistedSession() {
        do {
            guard var session = try persistenceStore.load() else { return }

            // A process exit during generation should never strand a job as "generating".
            for index in session.manifest.jobs.indices where session.manifest.jobs[index].status == .generating {
                session.manifest.jobs[index].status = .ready
            }

            manifest = session.manifest
            sourcePath = session.sourcePath

            if let selected = session.selectedJobID,
               let index = session.manifest.jobs.firstIndex(where: { $0.id == selected }),
               isActionable(session.manifest.jobs[index]) {
                selectedJobID = selected
                if session.manifest.jobs[index].status == .pending {
                    manifest?.jobs[index].status = .ready
                }
            } else if let first = session.manifest.jobs.firstIndex(where: isActionable) {
                selectedJobID = session.manifest.jobs[first].id
                if session.manifest.jobs[first].status == .pending {
                    manifest?.jobs[first].status = .ready
                }
            } else {
                selectedJobID = nil
            }

            persist()
        } catch {
            lastError = "Could not restore the previous batch: \(error.localizedDescription)"
        }
    }

    private func persist() {
        guard let manifest else {
            try? persistenceStore.clear()
            return
        }
        let session = BatchSession(
            manifest: manifest,
            selectedJobID: selectedJobID,
            sourcePath: sourcePath
        )
        do {
            try persistenceStore.save(session)
        } catch {
            lastError = "Could not save batch progress: \(error.localizedDescription)"
        }
    }

    private func advanceSelection(after index: Int) {
        guard var manifest else { return }

        let trailing = manifest.jobs.indices.dropFirst(index + 1)
        let leading = manifest.jobs.indices.prefix(index)
        let nextIndex = trailing.first(where: { isActionable(manifest.jobs[$0]) })
            ?? leading.first(where: { isActionable(manifest.jobs[$0]) })

        if let nextIndex {
            if manifest.jobs[nextIndex].status == .pending {
                manifest.jobs[nextIndex].status = .ready
            }
            self.manifest = manifest
            selectedJobID = manifest.jobs[nextIndex].id
        } else {
            self.manifest = manifest
            selectedJobID = nil
        }
        persist()
    }

    private func isActionable(_ job: ImageJob) -> Bool {
        [.pending, .ready, .failed].contains(job.status)
    }
}
