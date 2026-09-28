# ImageForge

ImageForge is a native macOS batch image-generation manager designed around zero-incremental-cost workflows first.

## Goal

Load a manifest of image jobs, walk the queue, pre-fill the selected image-generation provider, save accepted outputs with deterministic filenames, and resume cleanly after interruptions.

The first provider target is Apple's Image Playground / configured external provider on macOS Golden Gate. The architecture is intentionally provider-independent so local generation can later run fully unattended.

## Phase 0/1 scope

- JSON manifest import
- Queue state model
- Deterministic output paths
- Pause/resume/skip/retry semantics
- Provider abstraction
- Mock provider for development
- Apple Image Playground provider placeholder
- Native SwiftUI queue UI
- Example batch manifest

## Manifest

See `examples/aff-sample.json`.

```json
{
  "schemaVersion": 1,
  "project": "AFF Logos",
  "outputDirectory": "~/Pictures/AFF",
  "jobs": [
    {
      "id": "albany-empire",
      "filename": "albany-empire.png",
      "prompt": "Professional sports logo for the Albany Empire...",
      "width": 1024,
      "height": 1024,
      "provider": "apple"
    }
  ]
}
```

## Development

Open the package in Xcode and run the `ImageForge` executable target.

The package minimum is intentionally conservative for development. Apple-specific Golden Gate APIs should be isolated behind availability checks so the queue engine and tests stay portable.

## Roadmap

1. Validate Golden Gate Image Playground invocation behavior with an external provider.
2. Save approved result to the manifest's requested filename.
3. Automatically advance to the next queued job.
4. Add persistent resume metadata.
5. Add local-provider support for fully unattended generation.
