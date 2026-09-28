import SwiftUI
import UniformTypeIdentifiers
#if canImport(ImagePlayground)
import ImagePlayground
#endif

struct ContentView: View {
    @Environment(BatchQueueModel.self) private var queue
    @State private var importerPresented = false
    @State private var playgroundPresented = false
    @State private var playgroundJobID: String?

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { queue.selectedJobID },
                set: { queue.selectedJobID = $0 }
            )) {
                ForEach(queue.jobs) { job in
                    HStack(spacing: 10) {
                        statusIcon(for: job.status)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.filename)
                                .lineLimit(1)
                            Text(job.team ?? job.id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(job.id)
                }
            }
            .navigationTitle(queue.manifest?.project ?? "ImageForge")
            .toolbar {
                Button("Open Batch") { importerPresented = true }
            }
        } detail: {
            detail
        }
        .fileImporter(
            isPresented: $importerPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                if let url = try result.get().first {
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                    try queue.loadManifest(from: url)
                }
            } catch {
                queue.lastError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let job = queue.currentJob {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.filename).font(.title2).bold()
                        if let team = job.team {
                            Text(team)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        if let manifest = queue.manifest {
                            Text("\(queue.completedCount) / \(manifest.jobs.count) complete")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(job.provider.rawValue.capitalized)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }

                if job.assetType != nil || job.variant != nil || job.width != nil {
                    HStack(spacing: 16) {
                        if let assetType = job.assetType {
                            Label(assetType, systemImage: "photo")
                        }
                        if let variant = job.variant {
                            Label(variant, systemImage: "square.stack.3d.up")
                        }
                        if let width = job.width, let height = job.height {
                            Label("\(width) × \(height)", systemImage: "aspectratio")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                GroupBox("Prompt") {
                    ScrollView {
                        Text(job.generationPrompt)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(minHeight: 220)
                }

                if let referenceImage = job.referenceImage {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Reference: \(referenceImage)")
                            .textSelection(.enabled)
                        if let url = queue.referenceImageURL(for: job),
                           !FileManager.default.fileExists(atPath: url.path) {
                            Text("Missing")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption)
                }

                if let error = job.errorMessage ?? queue.lastError {
                    Text(error).foregroundStyle(.red)
                }

                Spacer()

                HStack {
                    Button("Skip") { queue.skipSelected() }
                        .disabled(!queue.canSkip(job))
                    Spacer()

                    #if DEBUG
                    Button("Test With Mock") {
                        Task { await queue.generateSelectedWithMockProvider() }
                    }
                    .disabled(!queue.canGenerate(job))
                    #endif

                    providerAction(for: job)
                }
            }
            .padding(24)
        } else {
            ContentUnavailableView(
                "Batch Complete",
                systemImage: "checkmark.circle",
                description: Text(queue.manifest == nil
                    ? "Open a JSON manifest to start an image queue."
                    : "There are no remaining image jobs.")
            )
        }
    }

    @ViewBuilder
    private func providerAction(for job: ImageJob) -> some View {
        switch job.provider {
        case .apple:
            appleGenerateButton(for: job)
        case .mock:
            Button("Generate With Mock") {
                Task { await queue.generateSelectedWithMockProvider() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!queue.canGenerate(job))
        case .local:
            Button("Local provider not implemented") {}
                .disabled(true)
        }
    }

    @ViewBuilder
    private func appleGenerateButton(for job: ImageJob) -> some View {
        #if canImport(ImagePlayground)
        if #available(macOS 27.0, *) {
            if let referenceURL = queue.referenceImageURL(for: job) {
                if FileManager.default.fileExists(atPath: referenceURL.path) {
                    Button("Generate in Image Playground") {
                        beginPlayground(for: job)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!queue.canGenerate(job))
                    .imagePlaygroundSheet(
                        isPresented: $playgroundPresented,
                        concept: job.generationPrompt,
                        sourceImageURL: referenceURL,
                        onCompletion: { url in completePlayground(url, fallbackJobID: job.id) },
                        onCancellation: { cancelPlayground(fallbackJobID: job.id) }
                    )
                    .imagePlaygroundOptions(playgroundOptions(for: job))
                    .imagePlaygroundGenerationStyle(
                        .externalProvider,
                        in: [.externalProvider]
                    )
                } else {
                    Button("Reference image missing") {}
                        .disabled(true)
                }
            } else {
                Button("Generate in Image Playground") {
                    beginPlayground(for: job)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!queue.canGenerate(job))
                .imagePlaygroundSheet(
                    isPresented: $playgroundPresented,
                    concept: job.generationPrompt,
                    sourceImage: nil,
                    onCompletion: { url in completePlayground(url, fallbackJobID: job.id) },
                    onCancellation: { cancelPlayground(fallbackJobID: job.id) }
                )
                .imagePlaygroundOptions(playgroundOptions(for: job))
                .imagePlaygroundGenerationStyle(
                    .externalProvider,
                    in: [.externalProvider]
                )
            }
        } else {
            Button("Requires macOS 27") {}
                .disabled(true)
        }
        #else
        Button("Image Playground unavailable") {}
            .disabled(true)
        #endif
    }

    private func beginPlayground(for job: ImageJob) {
        playgroundJobID = job.id
        queue.beginAppleGeneration(for: job.id)
        playgroundPresented = true
    }

    private func completePlayground(_ url: URL, fallbackJobID: String) {
        let completedJobID = playgroundJobID ?? fallbackJobID
        _ = queue.acceptAppleGeneratedImage(url, for: completedJobID)
        playgroundJobID = nil
    }

    private func cancelPlayground(fallbackJobID: String) {
        let cancelledJobID = playgroundJobID ?? fallbackJobID
        queue.cancelAppleGeneration(for: cancelledJobID)
        playgroundJobID = nil
    }

    #if canImport(ImagePlayground)
    @available(macOS 27.0, *)
    private func playgroundOptions(for job: ImageJob) -> ImagePlaygroundOptions {
        var options = ImagePlaygroundOptions()
        if let width = job.width, let height = job.height {
            options.sizeSpecification = .closest(
                to: CGSize(width: width, height: height)
            )
        }
        return options
    }
    #endif

    private func statusIcon(for status: ImageJob.Status) -> some View {
        let name: String = switch status {
        case .pending: "circle"
        case .ready: "play.circle"
        case .generating: "hourglass"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .skipped: "forward.end.circle"
        }
        return Image(systemName: name)
    }
}
