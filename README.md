# docker-tools

**Repo:** https://github.com/the-robot-lives/docker-tools

Docker image build and push helpers driven by shared config — target aliases, BuildKit/buildx multi-arch, multi-image selection, and local build state.

## What

`docker-build`, `docker-push`, `docker-sandbox`, and `docker-qemu11` — Bash CLIs that read Docker image targets from `infra-config.yaml` so builds are invoked by name (`docker-build backend`) rather than by hand-assembled `docker build` incantations.

## Why

The portfolio has dozens of apps, each with backend/frontend images and per-image platform quirks (amd64 emulation on arm hosts, cache mounts, cross-arch BEAM builds). Centralizing target definitions in `infra-config.yaml` gives one source of truth shared with the deploy tooling, and the wrappers add batch selection, build state, and the arm64 QEMU fix in one place.

## Getting Started

Prerequisites:

- Docker with BuildKit enabled; `docker buildx` for multi-arch
- Registry credentials (`docker login $K8_DOCKER_REGISTRY`)
- `yq`

```bash
make install    # four tools -> ~/.local/bin, plus bash/zsh completions
make test       # placeholder (no-op)
```

Also installed by the monorepo root `make install-utilities`. No deployment path here — releases are CI/CD-driven; this is the local/dev build lane.

## Usage

```bash
docker-build                          # auto-detect from CWD
docker-build backend                  # one target by configured name
docker-build --include backend,worker # comma list
docker-build --include 'codefre.sh/*' # glob over composite targets
docker-build --pick                   # interactive multi-select
docker-build --all
docker-build --push backend           # build and push
docker-build --native backend         # native arch only
docker-build --multiarch backend      # linux/amd64 + linux/arm64
docker-build --platform linux/amd64 backend
docker-build --no-cache backend

docker-push backend                   # push a built image
docker-sandbox therobotplans.com up -d
```

## Configuring Targets

Flat images (`project.docker.images[]`):

```yaml
project:
  docker:
    images:
      - name: backend            # CLI target name
        context: app/backend     # relative to the config file
        dockerfile: Dockerfile
        registry_path: my-org/backend
        build_args: { MIX_ENV: prod }
        platform: linux/amd64,linux/arm64
```

Composite projects (`project.type: composite`) describe many domain/service targets; the CLI target becomes `<domain>/<service>` (e.g. `docker-build codefre.sh/backend`).

Chart wiring (consumed by `deploy-service` in infra-tools, not here) adds a `helm:` stanza per image (`chart_path`, `values_path`, `format`) so CI can bump chart tags — see `docs/arch/deployment.md` at the monorepo root for the full build→deploy path.

## How It Works

- Registry/credentials come from `.envrc.k8.dc` or environment (`K8_DOCKER_REGISTRY`); image targets from the merged `infra-config.yaml` `project:` section. Legacy `docker.repos`/`docker.mappings` remain as fallback only when no project targets are discovered.
- `--include` matches configured target names, not paths.
- Build state lives in `.docker-state/` at the project root: `last` (last build), `shadow` (last pushed), `builds` (unpushed queue, capped 10), `pushes` (history, capped 10).
- `docker-sandbox` runs the app's `docker-compose.sandbox.yaml` stack pointed at production services via host port-forwards: `up [--dry-run] [-d]`, `logs`, `down`. The generated compose override points `DB_HOST`/`PGHOST`/ports at `host.docker.internal`; pass `--db <key>` if auto-detection picks the wrong database (keys from `.infra-config.yaml` `databases:`).
- `docker-qemu11` registers newer QEMU binfmt support for amd64 emulation on arm hosts (`--check` to inspect). Rerun after Docker Desktop/OrbStack restarts when Elixir/BEAM cross-arch builds fail under the stock `tonistiigi/binfmt`.
