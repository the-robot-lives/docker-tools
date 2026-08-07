# Project Architecture — Summary

## Overview

Bash 4+ utility package: Docker **build / push / sandbox / QEMU** layer for
Noizu k8s. Reads targets from merged `infra-config.yaml` `project:`; builds with
BuildKit/buildx (multi-arch default); pushes to `$K8_DOCKER_REGISTRY` with
Infisical patch versions; optional compose sandbox against kubectl-forwarded
DB/Redis. Install: `make install` → `~/.local/bin` (+ completions). Dual path:
`Portfolio/Utilities/source/docker-utils` ↔ `utilities/k8/docker-utils`. Runtime
deps: k8-lib (`docker-config.sh`, `docker-vsn.sh`, `assist.sh`, `bash-runtime.sh`).

## Core Components

- **`docker-build`** — config targets (flat or `<domain>/<service>`), globs,
  `--all`/`--pick`/`--include`; buildx cache; `--native`/`--multiarch`;
  zellij multi-pane or background logs; `--push`/`--release` → docker-push
- **`docker-push`** — Infisical `/docker-versions` counters; prod
  `v{M}.{m}.{N}` / non-prod `…-{env}.{S}`; `--remote` imagetools; `--release`
  Helm tag bump; `--headless` for agents/CI
- **`docker-sandbox`** — domain compose + port-forwards; override →
  `host.docker.internal`; state in `.docker-state/sandbox/`
- **`docker-qemu11`** — privileged QEMU 11 binfmt (amd64-on-arm64 Elixir);
  rerun after Docker VM restarts
- **completions/** — bash + zsh for build/push
- **`.docker-state/`** — `last`, `shadow`, `builds` (cap 10), `pushes` (cap 10)

## Configuration Flow

Targets: `project.docker.images[]` or composite `project.projects[].services[]`;
legacy `docker.repos`/`mappings` only if no project targets. Registry/Infisical
creds from `.envrc.k8.dc`. Optional `docker-hooks.sh` at `INFRA_ROOT`. Sandbox
also reads `databases:`.

## Key Decisions

- Config names/globs, not filesystem paths
- Shared k8-lib (not vendored) for discovery, state, Infisical preflight, vsn
- Infisical as monotonic version authority
- Build/push split + `.docker-state/` handoff; multi-arch push uses `--remote`
- zellij with `--no-zellij` / `--headless` agent path
- QEMU registration kept privileged and separate

## Ecosystem Fit

Below `deploy-service` (build → push → values → helm-upgrade). Charts in
upstream `noizu-infra`; siblings: helm-utils, secret-utils, cluster-utils.
