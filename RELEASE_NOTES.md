# ImageForge 0.1.0

First public ImageForge release.

## Highlights

- Native macOS SwiftUI batch queue for image-generation jobs.
- JSON manifest format with schema validation.
- Interactive Apple Image Playground external-provider workflow on macOS 27.
- Optional reference-image input and requested dimensions.
- Deterministic filenames and output directories.
- PNG, JPEG, HEIC/HEIF, and TIFF output transcoding.
- Atomic output replacement so a failed encode cannot destroy an existing asset.
- Persistent queue state with recovery after an interrupted generation.
- Skip, retry, cancel, and resume-friendly queue behavior.
- Visible import and persistence error handling.
- Example JSON manifests and manifest-format documentation.
- Apple Silicon release build produced by the project's self-hosted macOS runner.

## Installation

Download `ImageForge-macOS-arm64.zip` from this release, unzip it, and move `ImageForge.app` wherever you keep applications.

The current public build is ad-hoc signed rather than Developer ID notarized. macOS may require Control-clicking the app and choosing **Open** the first time.

## Requirements

- Apple Silicon Mac for the prebuilt release artifact.
- macOS 27 for the Apple Image Playground integration.
- The queue engine itself has a lower deployment target, but generation through Apple's Image Playground is availability-gated to macOS 27.

## Getting started

Start with `examples/example-batch.json`. Full manifest documentation is in `docs/MANIFEST.md`.
