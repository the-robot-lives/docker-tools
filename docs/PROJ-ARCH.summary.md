# Project Architecture — Summary

## Overview

Terminal utility package: the Docker build/push layer of the Noizu k8s
deployment toolchain. Three bash executables read image targets from the merged
`infra-config.yaml` `project:` section, build with BuildKit/buildx (multi-arch
capable), and push to `$K8_DOCKER_REGISTRY` with Infisical-resolved patch
versions. Installed to `~/.local/bin` via `make install` / repo-root
`make install-utilities`; depends at runtime on shared k8-lib
(`~/.local/share/k8-lib`).

## Core Components

- `bin/docker-build` — build configured targets (flat or composite `<domain>/<service>`); globs, `--pick`, parallel via zellij panes or background jobs; `--native`/`--multiarch`; optional `--push`/`--release`
- `bin/docker-push` — Infisical patch-version resolution, retag, push; `--release` bumps helm values tag; `--headless` for agents
- `bin/docker-qemu11` — privileged QEMU 11.x binfmt registration for amd64-on-arm64 (Elixir builds); rerun after Docker VM restarts
- `Makefile` — `install` copies `bin/*` to `$INSTALL_DIR`; `compile`/`test` no-ops
- `.docker-state/` — runtime build/push handoff state (`last`, `shadow`, `builds`, `pushes`)

## Configuration Flow

Targets from `project.docker.images[]` or composite `project.projects[].services[]`;
legacy `docker.repos`/`docker.mappings` only as fallback. Registry/creds from
`.envrc.k8.dc` env vars. Optional `docker-hooks.sh` sourced at `INFRA_ROOT`.

## Key Decisions

- Config-driven target names, not paths
- Shared k8-lib runtime dependency (docker-config.sh, docker-vsn.sh, assist.sh) rather than vendoring
- Infisical as the monotonic version authority
- zellij fan-out with background-job fallback; `--no-zellij`/`--headless` agent-safe
- Build/push split coordinated through `.docker-state/` files
- QEMU binfmt registration kept as a separate privileged tool

## Ecosystem Fit

One layer below `deploy-service` (infra-tools), which composes build + push +
Helm values bump + `helm-upgrade`. Helm charts live in the upstream
`noizu-infra` repo.
