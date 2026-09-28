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
                            Text(job.id)
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
                    VStack(alignment: .leading) {
                        Text(job.filename).font(.title2).bold()
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

                GroupBox("Prompt") {
                    ScrollView {
                        Text(job.prompt)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(minHeight: 220)
                }

                if let error = job.errorMessage ?? queue.lastError {
                    Text(error).foregroundStyle(.red)
                }

                Spacer()

                HStack {
                    Button("Skip") { queue.skipSelected() }
                        .disabled(queue.isRunning)
                    Spacer()
                    Button("Test Queue With Mock") {
                        Task { await queue.generateSelectedWithMockProvider() }
                    }
                    .disabled(queue.isRunning)

                    appleGenerateButton(for: job)
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
    private func appleGenerateButton(for job: ImageJob) -> some View {
        #if canImport(ImagePlayground)
        if #available(macOS 27.0, *) {
            Button("Generate in Image Playground") {
                playgroundJobID = job.id
                queue.beginAppleGeneration(for: job.id)
                playgroundPresented = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(queue.isRunning)
            .imagePlaygroundSheet(
                isPresented: $playgroundPresented,
                concept: job.prompt,
                sourceImage: nil,
                onCompletion: { url in
                    let completedJobID = playgroundJobID ?? job.id
                    _ = queue.acceptAppleGeneratedImage(url, for: completedJobID)
                    playgroundJobID = nil
                },
                onCancellation: {
                    let cancelledJobID = playgroundJobID ?? job.id
                    queue.cancelAppleGeneration(for: cancelledJobID)
                    playgroundJobID = nil
                }
            )
            .imagePlaygroundOptions(playgroundOptions(for: job))
            .imagePlaygroundGenerationStyle(
                .externalProvider,
                in: [.externalProvider]
            )
        } else {
            Button("Requires macOS 27") {}
                .disabled(true)
        }
        #else
        Button("Image Playground unavailable") {}
            .disabled(true)
        #endif
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
