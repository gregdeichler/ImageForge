# ImageForge Architecture

ImageForge is intentionally split between a small deterministic queue core and provider-specific generation behavior.

## Major components

### `BatchManifest` and `ImageJob`

These are the JSON-facing data models. Manifest validation keeps malformed batches out of the queue before generation starts.

### `BatchQueueModel`

The main-actor observable queue state. It owns selection, status transitions, progress, persistence coordination, retry/skip/cancel behavior, and advancement to the next actionable job.

### `BatchPersistenceStore`

Stores the active batch session in the user's Application Support directory. A job left in `generating` is reset to `ready` on recovery.

### `OutputWriter`

Owns deterministic output paths and image transcoding. Real image output is written to a temporary sibling file first and committed only after successful encoding, preserving an existing destination if encoding fails.

### Apple Image Playground

Apple's Image Playground integration is UI-driven and presented from SwiftUI. It is deliberately not modeled as an unattended `ImageGenerationProvider` because the provider owns an interactive system sheet.

### `ImageGenerationProvider`

Reserved for providers capable of unattended generation. The mock provider implements this protocol today; future local providers can use the same contract.

## State model

A job can be:

`pending → ready → generating → completed`

A generation failure becomes `failed`, which is actionable and retryable. A user may also move an actionable job to `skipped`.

Process interruption while a job is `generating` does not strand the queue: persisted `generating` state is restored as `ready`.

## Distribution

CI builds and tests on a self-hosted Apple Silicon Mac runner. Public releases package the release executable into `ImageForge.app`, ad-hoc sign it, zip it, and attach it to a GitHub Release.

The current app is not Developer ID notarized. Sandboxed distribution will require persisted security-scoped bookmarks for manifest, reference-image, and output-directory access; that work remains on the roadmap.
