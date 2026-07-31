# docker-utils — How To

Task-oriented guides for `docker-build`, `docker-push`, and `docker-qemu11`.
For *what this is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live*,
see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the tools

**Goal:** get `docker-build`, `docker-push`, `docker-qemu11` on your `$PATH`.
**Prereqs:** Docker with BuildKit, `docker buildx`, `yq`.

1. From this directory (or via the monorepo root):
   ```bash
   make install                     # installs to ~/.local/bin
   # or, from repo root:
   make install-utilities           # installs everything, incl. k8-lib
   ```
2. Log in to the registry you'll push to:
   ```bash
   docker login "$K8_DOCKER_REGISTRY"
   ```

**Verify:** `docker-build --help` prints usage.
**Gotchas:**
- `docker-build`/`docker-push` `source` shared `k8-lib` at
  `${K8_LIB_DIR:-~/.local/share/k8-lib}` — if that's missing, run
  `make install-utilities` from the monorepo root, not just this package.
- Registry/credential values come from `.envrc.k8.dc`, not this repo — see
  `docs/secret-management.md` at the monorepo root.

## How to: build and push one image

**Goal:** produce and publish a Docker image for a configured target.
**Prereqs:** target defined under `project.docker.images[]` (or composite
`project.projects[].services[]`) in the merged `infra-config.yaml`; registry
login done.

1. ```bash
   docker-build my-backend --push
   ```
2. Confirm the push prompt (or pass `--yes`/`-y` to skip it), or `--silent` to
   suppress the prompt but not the push.

**Verify:** `docker-push` prints the resolved tag and a successful push; the
new tag is visible in the registry.
**Gotchas:**
- Multi-arch is the default (`K8_DOCKER_MULTIARCH=true` in `.envrc.k8.dc`) and
  buildx cannot `--load` a multi-platform image locally — it publishes
  straight to the registry. For local-only iteration use `--native` (see
  below).
- `--push` triggers an Infisical preflight before any build work starts, so a
  broken Infisical session fails fast instead of after a 10-minute build —
  see [howto/diagnose-infisical-failures.md](howto/diagnose-infisical-failures.md)
  if it fails.

## How to: iterate fast on a single image locally

**Goal:** rebuild quickly for the host architecture only, without pushing.
**Prereqs:** same as above.

1. ```bash
   docker-build --native my-backend
   ```

**Verify:** image appears in `docker images` for local runs; no registry
tag is created.
**Gotchas:** `--native` implies single-arch + `--load`; combine with
`--no-cache` if you suspect stale layers.

## How to: build or push every configured image at once

**Goal:** rebuild/republish the whole project's images in one command.
**Prereqs:** targets configured; enough local resources for parallel builds.

1. ```bash
   docker-build --all            # every target, in parallel
   docker-build --all --push     # ...and push each after building
   docker-push  --all            # push already-built images
   ```
2. Or select interactively:
   ```bash
   docker-build --pick
   ```

**Verify:** one pane/job per target reports its own success/failure.
**Gotchas:**
- Parallel builds use zellij panes when zellij is available and more than one
  target is selected; otherwise they fall back to background jobs with logs
  under `.tmp/docker-build-logs/`. Force the fallback with `--no-zellij`.
- `--include` accepts a comma list and shell-style globs against configured
  target *names*, not file paths — e.g. `--include 'codefre.sh/*'` for every
  service under a composite domain.

## How to: run parallel builds inside your current zellij tab, in your shell

Reuse your open zellij tab and keep your login shell in each pane instead of
a bare bash.
→ *See [howto/zellij-pane-shell.md](howto/zellij-pane-shell.md)*

## How to: push non-interactively from a script or agent

**Goal:** push without any prompts, zellij, or local-only assumptions.
**Prereqs:** Infisical session already valid (or reachable non-interactively).
→ *See [howto/headless-push.md](howto/headless-push.md)*

## How to: preview a build/push without doing anything

**Goal:** see the resolved target(s), version, and command that *would* run.

1. ```bash
   docker-build my-backend --dry-run
   docker-push  my-backend --dry-run
   ```

**Verify:** output shows the plan but no image is built, tagged, or pushed.
**Gotchas:** `docker-build --dry-run --push` still shows the push plan but
skips both the containerd image-store probe and the actual push.

## How to: fix Elixir/BEAM cross-arch build failures on arm64 hosts

**Goal:** stop amd64-emulated Elixir/BEAM builds from failing under QEMU.
**Prereqs:** privileged Docker access (binfmt registration needs it).

1. ```bash
   docker-qemu11          # register newer QEMU binfmt support
   docker-qemu11 --check  # verify registration
   ```

**Verify:** the previously-failing `--platform linux/amd64` (or multiarch)
build of an Elixir/BEAM image now completes.
**Gotchas:** `tonistiigi/binfmt:latest` lags upstream QEMU; rerun
`docker-qemu11` after Docker Desktop/OrbStack restarts — the registration
doesn't survive a VM restart.

## How to: add a new image target to the config

**Goal:** make a new service buildable/pushable by name.
**Prereqs:** an `infra-config.yaml` (project-level or composite) this tool
already reads.

1. Flat project — add under `project.docker.images[]`:
   ```yaml
   project:
     docker:
       images:
         - name: worker
           context: app/worker
           dockerfile: Dockerfile
           registry_path: my-org/worker
   ```
2. Composite (incubator-style) project — add under the matching domain's
   `services[]` instead; the CLI target becomes `<domain>/<service>`.

**Verify:** `docker-build worker` (or `docker-build <domain>/worker`)
resolves and builds without an "unknown target" error.
**Gotchas:**
- `name` is both the alias and (default) `registry_path` — set
  `registry_path` explicitly if the repo path should differ.
- Legacy `docker.repos`/`docker.mappings` config is only consulted when *no*
  `project:` Docker targets were discovered at all — adding one real
  `project.docker.images[]` entry silently stops legacy fallback from being
  consulted for the rest.

## How to: bump the Helm values tag as part of a push

Update the Helm chart's `image.tag` to match the version you just pushed, in
the same step — via `docker-push --release` (or `docker-build --push
--release`).
→ *See [howto/bump-helm-values-tag.md](howto/bump-helm-values-tag.md)*

## How to: reuse your last build when pushing later

**Goal:** run `docker-push` from any directory and have it recall what you
just built.
**Prereqs:** ran `docker-build` at least once this session.

1. ```bash
   docker-push
   ```

**Verify:** within 60s of a build, `docker-push` offers that image
immediately; within 5 minutes it still suggests it; after that it lists
unpushed builds (capped at the last 10, from `.docker-state/builds`) to pick
from.
**Gotchas:** state is per checkout (`.docker-state/` at `$INFRA_ROOT`), so
this doesn't carry across different project directories.
