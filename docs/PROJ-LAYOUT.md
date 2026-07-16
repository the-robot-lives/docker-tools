# Project Layout

Terminal utility package: Docker image build/push helpers for the Noizu k8s
platform. Scripts read Docker targets from the merged `infra-config.yaml`
`project:` section and install to `~/.local/bin` via `make install`
(or the repo-root `make install-utilities`).

```
docker-utils/
├── bin/                        # Executable utilities (installed to ~/.local/bin)
│   ├── docker-build            #   Build configured image targets; aliases, buildx, --all/--pick parallel, --push/--release
│   ├── docker-push             #   Push built/configured images; Infisical patch versioning, retag, --update-helm, zellij panes
│   └── docker-qemu11           #   Register QEMU 11.x binfmt for amd64 emulation on arm hosts (privileged; rerun after Docker restarts)
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion for tools/agents
├── .gitignore                  # Ignores editor swap files, .env, .envrc.local, .DS_Store
├── Makefile                    # `make install` → copies bin/* to $INSTALL_DIR (default ~/.local/bin)
└── README.md                   # Start here — install, prerequisites, config sources, target schema
```

## Key Files Requiring Setup

| File / Var | Action |
|------------|--------|
| `K8_DOCKER_REGISTRY` | Export via `.envrc.k8.dc` or environment before build/push |
| Registry login | `docker login $K8_DOCKER_REGISTRY` |
| `infra-config.yaml` | Docker targets defined at repo root (`project.docker.images[]` / `project.projects[].services[]`) |

## Notes

- Prerequisites: Docker with BuildKit, `docker buildx`, `yq`.
- No `lib/` — scripts are self-contained bash (docker-build ~1057 lines, docker-push ~1088, docker-qemu11 ~71).
- `Makefile` `compile`/`test` targets are no-ops; only `install` does work.
