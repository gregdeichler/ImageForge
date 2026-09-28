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
        if let selectedJobID {
            return jobs.first { $0.id == selectedJobID }
        }
        return jobs.first { [.pending, .ready, .failed].contains($0.status) }
    }

    func loadManifest(from url: URL) throws {
        var loaded = try BatchManifest.load(from: url)
        if let first = loaded.jobs.firstIndex(where: { $0.status == .pending }) {
            loaded.jobs[first].status = .ready
        }
        manifest = loaded
        selectedJobID = loaded.jobs.first?.id
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
              let index = manifest?.jobs.firstIndex(where: { $0.id == selectedJobID }) else { return }
        manifest?.jobs[index].status = .skipped
        advanceSelection(after: index)
    }

    func beginAppleGeneration(for jobID: String) {
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }) else { return }
        manifest?.jobs[index].status = .generating
        manifest?.jobs[index].errorMessage = nil
        lastError = nil
        isRunning = true
        persist()
    }

    @discardableResult
    func acceptAppleGeneratedImage(_ temporaryURL: URL, for jobID: String) -> URL? {
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }),
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
        guard let index = manifest?.jobs.firstIndex(where: { $0.id == jobID }) else { return }
        manifest?.jobs[index].status = .ready
        isRunning = false
        persist()
    }

    func generateSelectedWithMockProvider() async {
        guard let selectedJobID,
              let index = manifest?.jobs.firstIndex(where: { $0.id == selectedJobID }),
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
               session.manifest.jobs.contains(where: { $0.id == selected && $0.status != .completed && $0.status != .skipped }) {
                selectedJobID = selected
            } else {
                selectedJobID = session.manifest.jobs.first {
                    [.pending, .ready, .failed].contains($0.status)
                }?.id
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
        let nextIndex = manifest.jobs.indices.dropFirst(index + 1).first {
            [.pending, .ready, .failed].contains(manifest.jobs[$0].status)
        }
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
}
