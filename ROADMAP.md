# ImageForge Roadmap

## Milestone 0 — Foundation
- [x] SwiftUI app shell
- [x] Codable JSON manifest
- [x] Queue status model
- [x] Output writer
- [x] Provider abstraction
- [x] Mock provider
- [x] Example manifest

## Milestone 1 — Golden Gate Apple provider
- [x] Confirm current Image Playground SwiftUI API surface on macOS 27
- [x] Present Image Playground from the selected queue job
- [x] Pre-populate prompt and requested size where supported
- [x] Lock Apple jobs to the configured external-provider style
- [x] Receive accepted generated image URL
- [x] Save to deterministic filename
- [x] Automatically select the next actionable job
- [x] Handle cancellation without losing queue state

## Milestone 2 — Persistence and production safety
- [x] Persist current queue progress in Application Support
- [x] Resume interrupted batches
- [x] Reset interrupted `generating` jobs to `ready`
- [x] Retry failed jobs without restarting the batch
- [x] Validate duplicate IDs/output filenames
- [x] Validate dimensions and safe output filenames
- [x] Support optional reference-image paths
- [x] Atomic output replacement that preserves the previous asset if encoding fails
- [x] Visible app-level persistence/import errors
- [x] Enforce supported output image formats
- [ ] Prompt hash + generation metadata sidecars
- [ ] Explicit output collision policy (overwrite / keep / version)
- [ ] Security-scoped bookmarks for sandboxed manifest/reference/output access

## Milestone 3 — Batch authoring
- [ ] Create/edit manifests in the app
- [ ] JSONL/CSV/TSV import
- [ ] Project-level prompt templates and variables
- [ ] Filename preview
- [ ] Batch validation report before starting
- [ ] Production presets (primary logo, one-color, helmet mark, etc.)

## Milestone 4 — Local generation
- [ ] Local provider discovery
- [ ] Fully unattended queue processing
- [ ] Concurrency controls
- [ ] Provider-specific options without leaking them into core queue logic

## Milestone 5 — Asset production workflow
- [ ] Approved-master tracking
- [ ] Derivative jobs from approved reference images
- [ ] Prompt/generation metadata sidecars
- [ ] Contact sheet / review mode
- [ ] Export project manifest and asset index
