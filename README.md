# ImageForge

ImageForge is a native macOS batch image-generation manager built around zero-incremental-cost workflows first.

It loads a manifest of image jobs, walks the queue, pre-fills Apple's Image Playground external-provider sheet, saves accepted outputs under deterministic filenames, and resumes cleanly after interruptions. Local/unattended providers can be added behind the same queue model later.

## Current status

- Native SwiftUI queue UI
- JSON manifest import
- Manifest validation before a batch is accepted
- Deterministic output paths
- Atomic output replacement so a failed encode cannot destroy an existing asset
- Pause/cancel/skip/retry-friendly queue state
- Persistent current-batch session in Application Support
- Automatic recovery of jobs interrupted while generating
- Apple Image Playground integration on macOS 27
- External-provider style support
- Requested image dimensions through ImagePlaygroundOptions
- Optional reference-image input
- Mock provider and tests
- Self-hosted Apple-silicon CI

Apple's external-provider flow is intentionally interactive: ImageForge can pre-fill the job, dimensions, and optional reference image, then save the accepted result and advance the queue. It does not attempt to automate clicks inside Apple's system sheet.

Apple documents image size as a requested/closest size, not a guarantee of an exact output pixel dimension.

## Manifest

See `examples/aff-sample.json`.

Schema version 2 adds production metadata while ImageForge continues to decode schema version 1 manifests.

```json
{
  "schemaVersion": 2,
  "project": "AFF Logos — Federal East Primaries",
  "outputDirectory": "~/Pictures/AFF/primary",
  "jobs": [
    {
      "id": "philadelphia-independence-primary",
      "team": "Philadelphia Independence",
      "assetType": "logo",
      "variant": "primary-full-color",
      "filename": "philadelphia-independence-primary.png",
      "prompt": "Professional major-league American football primary logo. One bold broken bell as the sole dominant object...",
      "negativePrompt": "text, letters, footballs, shields, mockups, gradients, chrome, 3D",
      "width": 2048,
      "height": 2048,
      "provider": "apple",
      "status": "pending",
      "tags": ["aff", "federal-east", "primary"]
    }
  ]
}
```

Optional `referenceImage` paths are resolved relative to the manifest file (or may be absolute paths). This is intended for derivative assets after a master mark has been approved.

### Validation

ImageForge rejects a manifest before queueing when it contains:

- unsupported schema versions
- empty project/output directory
- no jobs
- duplicate job IDs
- duplicate output filenames (case-insensitive)
- blank prompts
- path-like/unsafe output filenames
- only one of width/height
- non-positive dimensions
- unsupported image output extensions for real image providers

Supported image outputs are PNG, JPEG, HEIC/HEIF, and TIFF. ImageForge transcodes provider output into the requested file type rather than merely renaming provider bytes.

## AFF workflow

For the AFF branding project, use ImageForge as a production pipeline rather than asking the generator to redesign each franchise on every pass:

1. Generate the 32 locked full-color primary concepts.
2. Review and approve one master per team.
3. Use the approved master as `referenceImage` for one-color and helmet variants.
4. Resize approved artwork for 256/64/32 icons instead of regenerating those icons independently.

The included sample starts with the four locked Federal East concepts so the prompt structure can be validated before a full 32-team run.

## Development

Open the package in Xcode and run the `ImageForge` executable target.

```bash
swift build
swift test
```

The package minimum remains conservative so the queue engine and tests stay portable. Image Playground features are isolated behind framework and macOS 27 availability checks.

## Provider architecture

Apple's Image Playground path is UI-driven and lives in SwiftUI/BatchQueueModel. The `ImageGenerationProvider` protocol is reserved for providers that can generate without presenting provider-owned UI, such as the mock provider and future local providers.

This distinction avoids pretending Apple's interactive sheet is an unattended provider.
