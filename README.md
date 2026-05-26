# docker-tools — Docker Build & Push

Multi-architecture Docker image builds and registry push with version tracking.

## Installation

```bash
make install    # Installs docker-build, docker-push to ~/.local/bin
```

## Prerequisites

- Docker with BuildKit enabled
- `docker buildx` for multi-arch builds
- Registry credentials configured (`docker login $K8_DOCKER_REGISTRY`)
- `yq` for YAML parsing

## Configuration

All configuration lives in `infra-config.yaml` (see [k8-lib README](../k8-lib/README.md) for setup). Every tool accepts `--config <path>` to specify an alternative config file.

### Relevant Sections

```yaml
docker:
  registry: "ops.noizu.com"
```

Docker image repos are auto-discovered from `infra-config.yaml` `project.docker.images[]` entries.

### infra-config.yaml Project Integration

Images are auto-discovered from the `project` section of `infra-config.yaml`:

```yaml
docker:
  images:
    - name: my-app
      context: app/
      dockerfile: Dockerfile        # optional, default: Dockerfile
      registry_path: org/my-app     # optional, default: name
      build_args:
        NODE_ENV: production
      helm:                          # optional: post-push values update
        chart_path: helm/my-chart
        values_path: .image.tag
        format: tag                  # tag | image
```

## Usage

```bash
docker-build                    # Build all images in infra-config.yaml
docker-build my-app             # Build specific image
docker-build --pick             # Interactive selection
docker-build --no-cache         # Force fresh build
docker-build --push             # Build + push in one step

docker-push                     # Push last build to registry
docker-push my-app              # Push specific image
docker-push --update-helm       # Auto-update Helm values after push
```

## State

Build state tracked in `.docker-state/` at the project root:
- `last` — Last build variables
- `shadow` — Last pushed build
- `builds` — Unpushed build queue (max 10)
- `pushes` — Push history (max 10)
