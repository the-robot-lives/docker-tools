# Project Schema — Summary

> **No persistence layer** — bash CLI tools; no DB/SQL schema. Artifacts below are
> config inputs and local state files.

## Inputs

- **`infra-config.yaml` `project:`** — Docker targets.
  - Flat: `project.docker.images[]` — `name` (required), `context`, `dockerfile`, `registry_path`, `build_args`, `platform`.
  - Composite: `project.type: composite`, targets `<domain>/<service>` from `projects[].services[]`.
  - Helm wiring per image (deploy path): `helm.chart_path`, `helm.values_path`, `helm.format: tag`.
  - Legacy `docker.repos`/`docker.mappings`: fallback only when no project targets found.
- **Env**: `K8_DOCKER_REGISTRY` (registry host), `K8_LIB_DIR` (default `~/.local/share/k8-lib`), `INFRA_ROOT`, `K8_CONFIG`, `DOCKER_STATE_DIR`.

## State — `.docker-state/` (k8-lib-owned, cap 10 for queues)

| File | Format |
|------|--------|
| `last` | sourced vars `LAST_BUILD_{TIME,IMAGE,SHA,VSN}`; cleared on push |
| `shadow` | `SHADOW_*` copy of last build at push time |
| `builds` | line log `epoch\|image\|sha\|vsn` (unpushed queue) |
| `pushes` | line log `epoch\|image\|sha\|vsn` (history) |
| `sandbox/` | detached port-forward PID files |

## Generated

- `.tmp/docker-sandbox/` — compose override pointing containers at `host.docker.internal` (`DB_HOST`/`PGHOST` + ports).
- Requires app-side `docker-compose.sandbox.yaml` + env files (input, not fetched).
