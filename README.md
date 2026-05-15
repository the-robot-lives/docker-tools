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

### Required (in config.env)

```bash
K8_DOCKER_REGISTRY="ops.noizu.com"
```

### Optional Config Files (at project root)

**docker-repos.conf** — List of Docker repos to manage (one per line):

```
codefre.sh/backend
codefre.sh/frontend
noizu-website
```

If absent, repos are discovered from `project.yaml` `docker.images[]` entries.

**docker-mappings.conf** — Custom image-to-directory mappings (rarely needed):

```
# Format: image_name|dir_name|dockerfile|single_stage
my-api|web|Dockerfile.api|false
```

### project.yaml Integration

Images are auto-discovered from `project.yaml`:

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
docker-build                    # Build all images in project.yaml
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
