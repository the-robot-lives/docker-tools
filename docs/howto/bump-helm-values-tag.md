# How to: bump the Helm values tag as part of a push

**Goal:** update the Helm chart's `image.tag` to match the version you just
pushed, in the same step.
**Prereqs:** a Helm chart at `${INFRA_ROOT}/helm/<image-key>/` with a
`values.yaml` (prod) or `values-<env>.yaml` (non-prod, e.g. `values-stage.yaml`)
that already has an `image:`/`tag:` (or `repository:` matching the image)
block.

1. Pass `--release` to `docker-push` directly:
   ```bash
   docker-push my-backend --release
   ```
2. Or from `docker-build`, which passes it through after a successful push:
   ```bash
   docker-build my-backend --push --release
   ```

**Verify:** the console prints `📋  Updated values.yaml: image.tag →
<version>` and the chart's values file shows the new tag.

**Gotchas:**
- `--release` is the only flag that writes the Helm values file, and it runs
  the same values-tag update whether invoked standalone or via `docker-build
  --push --release`. There is no separate `--update-helm` flag — older
  monorepo docs referenced one, but it never existed in `bin/docker-push`.
- If `${INFRA_ROOT}/helm/<image-key>/` doesn't exist, or the expected values
  file is missing, the update is skipped with a `⚠️` warning — the push
  itself still succeeds.
- `BUILD_ENV` picks the values file: `prod`/`production` → `values.yaml`,
  anything else → `values-<env>.yaml`. Set it with `--prod`/`--stage`/`--dev`
  or `--env=<name>`.
