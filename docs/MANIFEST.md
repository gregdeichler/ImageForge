# ImageForge JSON Manifest

ImageForge uses JSON as its native batch format. A manifest describes the project, output directory, and ordered image jobs that make up the batch.

The current manifest schema version is **2**. Schema version 1 remains readable for backward compatibility.

## Minimal example

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
      "provider": "apple",
      "status": "pending"
    }
  ]
}
```

A fuller working example is available at `examples/example-batch.json`.

## Top-level fields

| Field | Required | Type | Description |
| --- | --- | --- | --- |
| `schemaVersion` | Yes | Integer | Manifest schema version. Current version: `2`. |
| `project` | Yes | String | Human-readable project name shown in the app. |
| `outputDirectory` | Yes | String | Destination directory for generated files. `~` is expanded. |
| `jobs` | Yes | Array | Ordered list of image jobs. Must contain at least one job. |

## Job fields

| Field | Required | Type | Description |
| --- | --- | --- | --- |
| `id` | Yes | String | Stable unique identifier within the manifest. |
| `filename` | Yes | String | Output filename only, never a path. |
| `prompt` | Yes | String | Main generation prompt. |
| `provider` | No | String | `apple`, `local`, or `mock`. Defaults to `apple`. |
| `status` | No | String | `pending`, `ready`, `generating`, `completed`, `failed`, or `skipped`. Defaults to `pending`. |
| `negativePrompt` | No | String | Appended to the prompt as an `Avoid:` instruction. |
| `referenceImage` | No | String | Absolute path or path relative to the manifest file. |
| `width` | No | Integer | Requested width. If present, `height` must also be present. |
| `height` | No | Integer | Requested height. If present, `width` must also be present. |
| `team` | No | String | Optional production metadata. |
| `assetType` | No | String | Optional production metadata such as `logo` or `illustration`. |
| `variant` | No | String | Optional production variant name. |
| `tags` | No | String array | Optional free-form organizational tags. |
| `errorMessage` | No | String | Runtime state written by ImageForge after a failed job. |

## Output formats

For real image providers, ImageForge accepts these filename extensions:

- `.png`
- `.jpg` / `.jpeg`
- `.heic` / `.heif`
- `.tif` / `.tiff`

ImageForge transcodes the provider's temporary image into the requested output format. It does not simply rename the provider's bytes.

## Validation

A manifest is rejected before queueing if it has:

- an unsupported schema version
- an empty project
- an empty output directory
- zero jobs
- duplicate job IDs
- duplicate output filenames, compared case-insensitively
- a blank prompt
- a filename containing path components
- an unsupported image output extension
- only one of width or height
- non-positive dimensions
- a blank `referenceImage` value

## Reference images

A relative reference path is resolved from the directory containing the manifest:

```text
project/
├── batch.json
└── references/
    └── approved-master.png
```

```json
"referenceImage": "references/approved-master.png"
```

Absolute paths and paths beginning with `~` are also supported.

## Queue state

Imported `generating` jobs are converted to `ready`, because ImageForge cannot resume a provider-owned generation session after import or process termination.

When ImageForge persists its current batch, it stores the manifest state, selected job, and source-manifest path in Application Support so the queue can recover after relaunch.

## Apple provider behavior

Apple Image Playground is interactive. ImageForge pre-fills the prompt, requested size, and optional reference image; the user completes the provider-owned sheet. When an image is accepted, ImageForge saves it under the manifest filename and advances the queue.

Requested dimensions are treated as a closest-size request by the Image Playground API rather than a guarantee of exact pixel dimensions.
