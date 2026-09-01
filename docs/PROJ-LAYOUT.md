# Project Layout

Terminal utility package: Docker image build/push/sandbox helpers for the Noizu
k8s platform. Scripts read Docker targets from the merged `infra-config.yaml`
`project:` section and install to `~/.local/bin` via `make install`
(or the repo-root `make install-utilities`, which also installs the shared
`k8-lib` runtime the scripts source).

```
docker-utils/
├── bin/                        # Executable utilities (installed to ~/.local/bin)
│   ├── docker-build            #   Build configured image targets; aliases, buildx, --all/--pick, --push/--native/--multiarch
│   ├── docker-push             #   Push built/configured images; retag, --release helm bump, Infisical patch versioning
│   ├── docker-sandbox          #   Live sandbox: kubectl port-forwards + generated compose override against forwarded prod services
│   └── docker-qemu11           #   Register QEMU 11.x binfmt for amd64 emulation on arm hosts (privileged; rerun after Docker restarts)
├── completions/                # Shell completions (installed by make install-completions)
│   ├── docker-build.bash       #   bash-completion for docker-build
│   ├── docker-push.bash        #   bash-completion for docker-push
│   ├── _docker-build           #   zsh completion for docker-build
│   └── _docker-push            #   zsh completion for docker-push
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md          #   This file
│   ├── PROJ-LAYOUT.summary.md  #   Tree-only companion for tools/agents
│   ├── PROJ-ARCH.md            #   Architecture overview (+ .summary.md)
│   ├── PROJ-HOWTO.md           #   Task howtos (+ .summary.md)
│   ├── PROJ-FAQ.md             #   FAQ (+ .summary.md)
│   └── howto/                  #   Focused runbooks (Infisical failures, headless push, helm tag bump, zellij panes)
├── .gitignore                  # Ignores .DS_Store, swap files, .env, .envrc.local
├── CHANGELOG.md                # Release notes
├── Makefile                    # `make install` → copies bin/* to $INSTALL_DIR (default ~/.local/bin) + completions; compile/test are no-ops
├── README.md                   # Start here — install, prerequisites, config sources, target schema
└── merge-notes.md              # Notes from monorepo-side consolidation sweep
```

## Runtime State (gitignored, created by the tools)

| Path | Purpose |
|------|---------|
| `.docker-state/` | Per-project build/push state (`last`, `shadow`, `builds`, `pushes`) at the infra-config root |
| `.docker-state/sandbox/` | Detached-sandbox port-forward PIDs |
| `.tmp/docker-sandbox/` | Generated docker compose override files |

## Key Files Requiring Setup

| File / Var | Action |
|------------|--------|
| `K8_DOCKER_REGISTRY` | Export via `.envrc.k8.dc` or environment before build/push |
| Registry login | `docker login $K8_DOCKER_REGISTRY` |
| `infra-config.yaml` | Docker targets defined at repo root (`project.docker.images[]` / `project.projects[].services[]`) |
| `K8_LIB_DIR` | Optional override for the shared `k8-lib` runtime (default `~/.local/share/k8-lib`) |

## Notes

- Prerequisites: Docker with BuildKit, `docker buildx`, `yq`, Bash 4+ (docker-sandbox rejects macOS /bin/bash 3.2).
- No `lib/` — scripts are self-contained bash (docker-build ~1083 lines, docker-push ~1118, docker-sandbox ~565, docker-qemu11 ~71).
- Sandbox stacks also require the target app's `docker-compose.sandbox.yaml` and its env/init step (the tool forwards services; it does not fetch app secrets).
