# Home Mac self-hosted runner

ImageForge is intentionally pinned to a dedicated runner label:

```yaml
runs-on: [self-hosted, macOS, ARM64, imageforge]
```

The existing Allocator runner on the same Mac is repository-scoped to
`gregdeichler/The-Allocator-macOS`, so it cannot also service this personal
`gregdeichler/ImageForge` repository. Run a **second runner instance on the
same Mac** instead of modifying or replacing the Allocator runner.

## Registration

In GitHub:

1. Open `gregdeichler/ImageForge`.
2. Go to **Settings → Actions → Runners**.
3. Choose **New self-hosted runner**.
4. Select **macOS** and **ARM64**.
5. On the home Mac, follow GitHub's generated install commands in a new
   directory such as:

   ```text
   ~/actions-runner-imageforge
   ```

6. When `config.sh` asks for runner labels, include:

   ```text
   imageforge
   ```

   GitHub supplies the standard `self-hosted`, `macOS`, and `ARM64`
   labels automatically.

7. Give the runner a distinct name such as:

   ```text
   home-mac-imageforge
   ```

8. Install/start it as a service using the exact `svc.sh` commands shown by
   the downloaded runner package.

Do **not** reuse the Allocator runner directory or remove its registration.
Multiple runner instances can coexist on the same Mac when each has its own
directory and service.

## Verification

Run the **macOS CI** workflow manually. A correctly attached home runner will
pick up the job because it matches all four labels. The workflow prints the
macOS version, architecture, Xcode version, and Swift version before building
and testing ImageForge.
