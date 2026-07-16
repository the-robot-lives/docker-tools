# Changelog — utilities/k8/docker-utils

## [Unreleased]
- Added PROJ-ARCH.md / PROJ-ARCH.summary.md / PROJ-LAYOUT.md / PROJ-LAYOUT.summary.md under `docs/` (NPL doc scaffolding, no behavior change)

## [m3-zellij-panes] — 2026-07-08 — tag: `utilities-k8-docker-utils/m3-zellij-panes`
Milestone summary: `docker-build`'s multi-target zellij mode learned to reuse the caller's existing zellij tab instead of always spawning a new session, and the pane shell became configurable/auto-detected instead of hardcoded to bash.

### Added
- `docker-build` detects an active zellij session (`$ZELLIJ`/`$ZELLIJ_SESSION_NAME`) and adds build panes to the current tab via `zellij action new-pane` instead of spawning a new session/layout
- `DOCKER_BUILD_PANE_SHELL` env var to override the shell used for build panes; falls back to auto-detecting the parent process's shell, then `$SHELL`, then bash
- Pane commands invoke `docker-build` by absolute path and `exec` into the resolved shell on completion, so panes stay open in the user's actual shell rather than a bare bash

### Fixed
- KDL layout generation now shell-escapes pane commands (`_kdl_escape`) instead of interpolating raw strings, avoiding malformed layouts for images/paths with special characters

## [m2-infisical-hardening] — 2026-06-14 — tag: `utilities-k8-docker-utils/m2-infisical-hardening`
Milestone summary: Infisical auth/project-lookup failures in `docker-push` went from silent/opaque to diagnosable (HTTP status + curl stderr + response body surfaced), and the same Infisical login was hoisted into a shared preflight so `docker-build --push` fails fast before wasting build time; `docker-push` also gained a scriptable `--headless` mode.

### Added
- `_infisical_preflight` shared step: `docker-build` runs it up front when `--push`-ing (non-dry-run) and exports the resulting token/project/creds so `docker-push` can skip re-authenticating
- `docker-push --headless` flag (implies `--yes --no-zellij --remote`) for non-interactive/scripted pushes
- Infisical auth and project-slug-lookup failures now report HTTP status code, captured curl stderr, and response body instead of a bare "Authentication failed"

### Fixed
- `docker-build --dry-run` no longer probes containerd image-store capability or attempts to trigger the push phase (both were previously dry-run-gated inconsistently between two commits, then settled: containerd probe always runs, push phase gate moved into the shared preflight)

## [m1-initial-import] — 2026-06-13 — tag: `utilities-k8-docker-utils/m1-initial-import`
Milestone summary: `docker-utils` merged into the monorepo as a git subtree, bringing `docker-build`, `docker-push`, and `docker-qemu11` plus their Makefile and README.

### Added
- `bin/docker-build`, `bin/docker-push`, `bin/docker-qemu11` — Docker image build/push/QEMU-emulation tooling (~2,360 lines combined)
- `Makefile` and `README.md` for standalone install/use
