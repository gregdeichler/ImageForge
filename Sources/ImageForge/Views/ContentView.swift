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
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 340)
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
                queue.reportAppError(error.localizedDescription)
            }
        }
        .alert(
            "ImageForge",
            isPresented: Binding(
                get: { queue.appError != nil },
                set: { if !$0 { queue.dismissAppError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                queue.dismissAppError()
            }
        } message: {
            Text(queue.appError ?? "")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader

            Divider()

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
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                    .tag(job.id)
                }
            }
            .listStyle(.sidebar)

            Divider()

            sidebarActions
        }
        .background(.regularMaterial)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(queue.manifest?.project ?? "ImageForge")
                .font(.title3.weight(.semibold))
                .lineLimit(2)

            if let manifest = queue.manifest {
                ProgressView(
                    value: Double(queue.finishedCount),
                    total: Double(max(manifest.jobs.count, 1))
                )

                Text(progressSummary(for: manifest))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Batch image generation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var sidebarActions: some View {
        HStack(spacing: 8) {
            Button {
                importerPresented = true
            } label: {
                Label("Open Batch", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)

            if queue.manifest != nil {
                Button(role: .destructive) {
                    _ = queue.clearBatch()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .disabled(queue.isRunning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    @ViewBuilder
    private var detail: some View {
        if let job = queue.currentJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    jobHeader(job)
                    jobMetadata(job)
                    promptCard(job)
                    referenceRow(job)
                    errorRow(job)

                    Divider()

                    jobActions(job)
                }
                .frame(maxWidth: 860, alignment: .leading)
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        } else if queue.manifest == nil {
            ContentUnavailableView {
                Label("No Batch Loaded", systemImage: "photo.stack")
            } description: {
                Text("Open a JSON manifest to start an image queue.")
            } actions: {
                Button("Open Batch") {
                    importerPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                "Batch Complete",
                systemImage: "checkmark.circle",
                description: Text("There are no remaining image jobs.")
            )
        }
    }


    private func progressSummary(for manifest: BatchManifest) -> String {
        let total = manifest.jobs.count
        if queue.skippedCount > 0 {
            return "\(queue.finishedCount) of \(total) finished • \(queue.completedCount) complete • \(queue.skippedCount) skipped"
        }
        return "\(queue.completedCount) of \(total) complete"
    }

    private func jobHeader(_ job: ImageJob) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(job.filename)
                    .font(.title2.weight(.semibold))
                    .textSelection(.enabled)

                if let team = job.team {
                    Text(team)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)

            Text(job.provider.rawValue.capitalized)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary, in: Capsule())
        }
    }

    @ViewBuilder
    private func jobMetadata(_ job: ImageJob) -> some View {
        if job.assetType != nil || job.variant != nil || job.width != nil {
            HStack(spacing: 14) {
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
    }

    private func promptCard(_ job: ImageJob) -> some View {
        GroupBox {
            ScrollView {
                Text(job.generationPrompt)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(minHeight: 180, maxHeight: 320)
        } label: {
            Label("Prompt", systemImage: "text.alignleft")
                .font(.headline)
        }
    }

    @ViewBuilder
    private func referenceRow(_ job: ImageJob) -> some View {
        if let referenceImage = job.referenceImage {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                Text(referenceImage)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let url = queue.referenceImageURL(for: job),
                   !FileManager.default.fileExists(atPath: url.path) {
                    Text("Missing")
                        .foregroundStyle(.red)
                        .fontWeight(.medium)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func errorRow(_ job: ImageJob) -> some View {
        if let error = job.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.callout)
                .textSelection(.enabled)
        }
    }

    private func jobActions(_ job: ImageJob) -> some View {
        HStack(spacing: 10) {
            Button("Skip") {
                queue.skipSelected()
            }
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
            .foregroundStyle(statusColor(for: status))
    }

    private func statusColor(for status: ImageJob.Status) -> Color {
        switch status {
        case .completed: .green
        case .failed: .red
        case .generating: .orange
        case .ready: .accentColor
        case .pending, .skipped: .secondary
        }
    }
}
