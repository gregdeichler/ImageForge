<p align="center">
  <img src="assets/AppIcon.png" alt="ImageForge app icon" width="180">
</p>

<h1 align="center">ImageForge</h1>

<p align="center">
  Native macOS batch image generation from reproducible JSON manifests.
</p>

<p align="center">
  <a href="https://github.com/gregdeichler/ImageForge/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/gregdeichler/ImageForge"></a>
  <a href="https://github.com/gregdeichler/ImageForge/actions/workflows/mac-ci.yml"><img alt="macOS CI" src="https://github.com/gregdeichler/ImageForge/actions/workflows/mac-ci.yml/badge.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-111111?logo=apple">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white">
</p>

ImageForge is a native macOS batch image-generation manager built around reproducible JSON jobs and zero-incremental-cost workflows first. The checked-in `assets/AppIcon.png` is the canonical project artwork used by the packaged Mac app and this repository.

It loads a JSON manifest, walks an ordered queue, pre-fills Apple's Image Playground external-provider sheet, saves accepted outputs under deterministic filenames, and persists progress so an interrupted batch can resume cleanly.

[Download the latest release](https://github.com/gregdeichler/ImageForge/releases/latest) · [Manifest documentation](docs/MANIFEST.md) · [Architecture](docs/ARCHITECTURE.md) · [Roadmap](ROADMAP.md)

## What it does

- Native SwiftUI macOS interface.
- JSON is the native batch format.
- Validates manifests before accepting a batch.
- Persistent queue state in Application Support.
- Recovers interrupted `generating` jobs as `ready`.
- Supports skip, retry, cancel, and resume workflows.
- Integrates with Apple Image Playground on macOS 27.
- Seeds prompt, requested dimensions, and an optional reference image.
- Uses deterministic filenames and output directories.
- Transcodes provider output to PNG, JPEG, HEIC/HEIF, or TIFF.
- Writes replacements atomically so a failed encode cannot destroy an existing good asset.
- Keeps app-level import/persistence errors separate from per-job generation errors.
- Includes a mock unattended provider for testing and a provider contract for future local generation.
- Builds and tests on a self-hosted Apple Silicon macOS runner.
- Publishes packaged `ImageForge.app` ZIPs to GitHub Releases.

Apple's external-provider flow is intentionally interactive. ImageForge prepares the job and presents Apple's provider-owned sheet; it does not automate clicks inside that system UI.

## Download

**Current public release: v0.1.1.** Use the **Releases** page for normal installs:

https://github.com/gregdeichler/ImageForge/releases

Download `ImageForge-macOS-arm64.zip`, unzip it, and move `ImageForge.app` wherever you keep applications.

The current release artifact is built for Apple Silicon and is ad-hoc signed rather than Developer ID notarized. macOS may require Control-clicking the app and choosing **Open** on first launch.

### Requirements

- Apple Silicon Mac for the prebuilt release artifact.
- macOS 27 for Apple Image Playground generation.
- The Swift package has a macOS 15 deployment target so non-Image-Playground queue code and tests remain portable.

## Quick start

1. Download and open ImageForge.
2. Copy `examples/example-batch.json` somewhere you can edit it.
3. Change `project`, `outputDirectory`, prompts, and filenames.
4. In ImageForge, choose **Open Batch**.
5. Select a job and choose **Generate in Image Playground**.
6. Accept the generated image in Apple's sheet.
7. ImageForge saves it using the manifest filename and advances to the next actionable job.

A production-oriented AFF example is also included at `examples/aff-sample.json`.

## JSON manifest

JSON is a first-class format in ImageForge, not an interchange format layered on top of another project file.

Minimal schema-v2 example:

```json
{
  "schemaVersion": 2,
  "project": "Example Project",
  "outputDirectory": "~/Pictures/ImageForge/Example",
  "jobs": [
    {
      "id": "hero-image",
      "filename": "hero-image.png",
      "prompt": "A bold editorial illustration with a clean central silhouette.",
      "negativePrompt": "text, watermark, mockup",
      "width": 2048,
      "height": 2048,
      "provider": "apple",
      "status": "pending",
      "tags": ["example"]
    }
  ]
}
```

See **[docs/MANIFEST.md](docs/MANIFEST.md)** for every field, supported provider/status value, validation rule, reference-image behavior, and output format.

### Supported image outputs

Real image providers may write:

- PNG
- JPEG
- HEIC / HEIF
- TIFF

ImageForge transcodes the provider's temporary result into the file type requested by the manifest filename. It does not merely rename provider bytes.

## Reference images

A job can provide `referenceImage` as an absolute path, a `~` path, or a path relative to the JSON manifest:

```json
{
  "id": "approved-master-variant",
  "filename": "approved-master-variant.png",
  "prompt": "Create a simplified alternate treatment of the approved artwork.",
  "referenceImage": "references/approved-master.png",
  "provider": "apple",
  "status": "pending"
}
```

This supports workflows where an approved master is used to generate controlled derivative assets.

## Queue behavior

The normal state progression is:

```text
pending → ready → generating → completed
```

Generation errors become `failed` and remain retryable. A user can mark an actionable job `skipped`. Completed and skipped jobs both count toward finished batch progress, while remaining distinguishable in the UI.

If the app exits while a job is `generating`, that job is restored as `ready` on next launch.

## Output safety

ImageForge does not delete an existing destination before proving the replacement can be written.

For real image providers it:

1. decodes the provider result,
2. writes the requested format to a temporary sibling file,
3. finalizes the image,
4. replaces the destination only after successful encoding.

If conversion fails, an existing output remains intact.

## Architecture

The core pieces are intentionally small:

- `BatchManifest` / `ImageJob` — JSON-facing data model and validation.
- `BatchQueueModel` — state transitions, selection, progress, retry/skip/cancel, and persistence coordination.
- `BatchPersistenceStore` — active-session storage and recovery.
- `OutputWriter` — deterministic paths, transcoding, and atomic output replacement.
- Apple Image Playground integration — interactive SwiftUI provider path.
- `ImageGenerationProvider` — contract reserved for unattended providers such as the mock provider and future local backends.

See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for more detail.

## Build from source

Open the package in Xcode, or use Swift Package Manager:

```bash
swift build
swift test
```

To build the same packaged application used by CI and Releases:

```bash
bash scripts/package-macos.sh
```

The result is:

```text
dist/ImageForge.app
dist/ImageForge-macOS-arm64.zip
```

## Releases

The repository stores the public version in `VERSION`.

When a version/release change lands on `main`, the release workflow:

1. builds the release executable,
2. runs the test suite,
3. packages and verifies `ImageForge.app`,
4. ad-hoc signs the app,
5. creates the matching `vX.Y.Z` GitHub Release,
6. attaches `ImageForge-macOS-arm64.zip`.

Release notes live in `RELEASE_NOTES.md`.

## CI

`.github/workflows/mac-ci.yml` runs build and tests on the self-hosted Apple Silicon runner. Non-PR builds also create a downloadable Actions artifact.

`.github/workflows/release.yml` is responsible for durable GitHub Release artifacts.

## Current limitations

- Apple Image Playground generation remains interactive by design.
- Requested Image Playground dimensions are a closest-size request rather than a guarantee of exact provider output dimensions.
- The public artifact is not Developer ID notarized.
- A future sandboxed distribution will require persisted security-scoped bookmarks for manifests, reference images, and output directories.
- The local unattended generation provider is not implemented yet.

See **[ROADMAP.md](ROADMAP.md)** for planned work.

## Project examples

- `examples/example-batch.json` — generic schema-v2 starter manifest.
- `examples/aff-sample.json` — production-oriented multi-job branding example.

## Branding

The canonical project artwork is `assets/AppIcon.png`. The release packaging step converts that image into the macOS `AppIcon.icns` bundled with `ImageForge.app`, so the application and public repository use the same identity.

## Repository status

This repository is public. No open-source license has been declared yet, so public visibility should not be interpreted as granting rights beyond GitHub's normal repository-viewing and forking functionality.
