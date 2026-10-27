# AGENT-README

> Orientation for AI coding agents working in this repo. Human docs: README.md.

## Type

scripts+cli-tool

## Purpose

Docker image build/push/sandbox helpers driven by shared `infra-config.yaml` targets: `docker-build`, `docker-push`, `docker-sandbox`, `docker-qemu11` — invoked by name instead of hand-assembled `docker build` incantations.

## Stack

Bash CLIs (`bin/`), `yq`, Docker with BuildKit/buildx; target aliases/composites read from the monorepo's `.infra-config.yaml` `project:` section.

## Dev mode

```bash
make install    # four tools -> ~/.local/bin + bash/zsh completions
make test       # placeholder (no-op)
docker-build backend            # one target by configured name
docker-build --multiarch backend
```

## Ports / URLs

- none (library/CLI)

## Tests

```bash
make test   # no-op placeholder
```

## Gotchas

- Local/dev build lane only — releases are CI/CD-driven (GHA + ArgoCD); never `docker-push` to ship.
- Registry/credentials come from `.envrc.k8.dc` or env (`K8_DOCKER_REGISTRY`); `yq` is a prerequisite.
- `docker-qemu11` registers QEMU 11.x binfmt (privileged) for amd64-on-arm64 builds — rerun it after Docker VM restarts.
- Chart wiring (`helm:` stanzas) is consumed by `deploy-service` in infra-tools, not here.
