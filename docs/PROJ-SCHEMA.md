# Project Schema — Config & Data Artifacts

> **No persistence layer.** docker-utils is a bash CLI tool package with no
> database, no SQL schema, and no Liquibase changelogs. This document therefore
> covers the persistence/config artifacts it *does* have: the `infra-config.yaml`
> Docker-target stanzas it consumes, environment/secret inputs, and the local
> state files it writes. There are no ERDs — data lives in flat config files and
> sourced/line-log state files, not tables.

## 1. `infra-config.yaml` — Docker Target Config (input, authoritative)

Resolved by the shared k8-lib `docker-config.sh` from the monorepo root.
Two shapes: flat images and composite projects.

### 1a. Flat images — `project.docker.images[]`

| Field | Required | Type | Default | Description |
|-------|----------|------|---------|-------------|
| `name` | Yes | string | — | CLI target name / alias (`docker-build <name>`) |
| `context` | No | path | config dir | Build context path relative to `infra-config.yaml` |
| `dockerfile` | No | path | `Dockerfile` | Dockerfile path relative to `context` |
| `registry_path` | No | string | `name` | Path under `$K8_DOCKER_REGISTRY` |
| `build_args` | No | map | — | Static `--build-arg` KEY: VALUE pairs |
| `platform` | No | string | — | Per-image platform override (e.g. `linux/amd64,linux/arm64`) |

### 1b. Composite — `project.type: composite`

| Field | Required | Description |
|-------|----------|-------------|
| `project.name` | Yes | Project key; CLI targets become `<domain>/<service>` |
| `project.projects[]` | Yes | List of domain entries |
| `projects[].domain` | Yes | Domain prefix of the CLI target (e.g. `codefre.sh`) |
| `projects[].base_path` | Yes | Project path relative to `paths.projects_dir` |
| `projects[].services[]` | Yes | Same image field schema as §1a |

### 1c. Build→deploy wiring — `helm:` stanza (per-project `project.yaml`)

Consumed by `deploy-service` (infra-tools) and `docker-push --release`; optional on each image:

| Field | Type | Description |
|-------|------|-------------|
| `helm.chart_path` | path | Chart directory relative to project |
| `helm.values_path` | string | YAML path of the image tag in values (e.g. `.image.tag`) |
| `helm.format` | enum | `tag` — write the version tag as the Helm image tag |

### 1d. Legacy fallbacks

`docker.repos` and `docker.mappings` are honored **only when no `project:` Docker
targets were discovered**. New config should not use them.

## 2. Environment & Secrets (input)

| Var | Source | Purpose |
|-----|--------|---------|
| `K8_DOCKER_REGISTRY` | `.envrc.k8.dc` / env | Registry host for push/retag; `docker login` required |
| `K8_LIB_DIR` | env | Shared runtime dir; default `~/.local/share/k8-lib` |
| `INFRA_ROOT` | env / CWD | Root holding `infra-config.yaml` and `.docker-state/` |
| `K8_CONFIG` | `--config=` flag or env | Alternate k8-lib config file |
| `DOCKER_STATE_DIR` | derived | `${INFRA_ROOT}/.docker-state` (overridable) |

Registry credentials are never stored by this package — they live in the
standard docker credential store; secret values flow through dc/Infisical per
monorepo convention.

## 3. Local State — `.docker-state/` (written by tools)

Owned by k8-lib `docker-config.sh`; created under `INFRA_ROOT`. Format contract:

| File | Format | Cap | Purpose |
|------|--------|-----|---------|
| `last` | sourced bash vars: `LAST_BUILD_TIME` (epoch), `LAST_BUILD_IMAGE`, `LAST_BUILD_SHA`, `LAST_BUILD_VSN` | 1 | Most recent build; cleared on push |
| `shadow` | same shape, `SHADOW_*` prefix | 1 | Copy of `last` at push time (last pushed build) |
| `builds` | line log `epoch\|image\|sha\|vsn` | 10 | Unpushed build queue |
| `pushes` | line log `epoch\|image\|sha\|vsn` | 10 | Push history |
| `sandbox/` | PID files for detached port-forwards | — | `docker-sandbox up -d` bookkeeping |

Lifecycle: build → `last` + `builds` append; push → `last`→`shadow`, matching
entry removed from `builds`, `pushes` append. Queue/history capped by
`tail -10` rewrite.

## 4. Generated Sandbox Artifacts (written by `docker-sandbox`)

| Artifact | Format | Purpose |
|----------|--------|---------|
| `.tmp/docker-sandbox/` compose override | docker-compose YAML | Points sandbox/backend/migrations containers at `host.docker.internal`; sets `DB_HOST`, `DATABASE_HOST`, `PGHOST` + port equivalents |
| App `docker-compose.sandbox.yaml` + env files | docker-compose YAML + `.env` | **Input**, must exist in the target app; the tool forwards services but never fetches app secrets |

## 5. Artifact Relationship Map

```mermaid
flowchart LR
    IC[infra-config.yaml<br/>project.docker.images[] /<br/>projects[].services[]] --> DC[k8-lib docker-config.sh<br/>target resolution]
    EV[K8_DOCKER_REGISTRY +<br/>docker credentials] --> DB[bin/docker-build]
    EV --> DP[bin/docker-push]
    DC --> DB
    DC --> DS[bin/docker-sandbox]
    DB --> ST[.docker-state/<br/>last, builds]
    DP --> ST
    ST -->|last to shadow| SH[.docker-state/shadow]
    DP -->|helm: stanza| HV[per-project project.yaml<br/>image.tag bump]
    DC --> OV[.tmp/docker-sandbox/<br/>compose override]
    OV --> SC[app docker-compose.sandbox.yaml<br/>+ env files]
```

## Summary File

See [PROJ-SCHEMA.summary.md](PROJ-SCHEMA.summary.md) for the condensed reference.
