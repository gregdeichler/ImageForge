# ImageForge Roadmap

## Milestone 0 — Foundation
- [x] SwiftUI app shell
- [x] Codable JSON manifest
- [x] Queue status model
- [x] Output writer
- [x] Provider protocol
- [x] Mock provider
- [x] Example manifest

## Milestone 1 — Golden Gate Apple provider
- [ ] Confirm current Image Playground API surface on macOS Golden Gate
- [ ] Present Image Playground from the selected queue job
- [ ] Pre-populate prompt/concepts and requested size where supported
- [ ] Prefer configured external provider when available
- [ ] Receive accepted generated image URL
- [ ] Save to deterministic filename
- [ ] Automatically select the next job
- [ ] Handle cancel without losing queue state

## Milestone 2 — Persistence
- [ ] Persist queue progress alongside manifest
- [ ] Resume interrupted batches
- [ ] Prompt hash + generation metadata sidecars
- [ ] Retry failed jobs

## Milestone 3 — Batch authoring
- [ ] Create/edit manifests in the app
- [ ] JSONL/CSV/TSV import
- [ ] Template variables
- [ ] Filename preview and collision validation

## Milestone 4 — Local generation
- [ ] Local provider discovery
- [ ] Fully unattended queue processing
- [ ] Concurrency controls
- [ ] Provider-specific options without leaking them into core queue logic
