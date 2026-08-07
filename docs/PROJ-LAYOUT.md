# Project Layout

Terminal utility package: Docker image build/push helpers, live sandbox
compose against port-forwarded services, and QEMU binfmt registration for the
Noizu k8s platform. Scripts read targets from the merged `infra-config.yaml`
`project:` section and install to `~/.local/bin` via `make install`
(or the repo-root `make install-utilities`). Completions install under
`$XDG_DATA_HOME` (default `~/.local/share`).

```
docker-utils/
├── bin/                            # Bash CLIs → ~/.local/bin
│   ├── docker-build                #   Build configured targets; buildx, --all/--pick, --push/--release
│   ├── docker-push                 #   Push w/ Infisical patch versioning; --release helm bump; --headless
│   ├── docker-sandbox              #   Compose sandbox + kubectl port-forwards to prod DB/services
│   └── docker-qemu11               #   Register QEMU 11.x binfmt (privileged; rerun after Docker restarts)
├── completions/                    # Shell completions (make install-completions)
│   ├── docker-build.bash           #   bash-completion for docker-build
│   ├── docker-push.bash            #   bash-completion for docker-push
│   ├── _docker-build               #   zsh compdef for docker-build
│   └── _docker-push                #   zsh compdef for docker-push
├── docs/                           # Documentation
│   ├── PROJ-ARCH.md                #   Architecture overview
│   ├── PROJ-ARCH.summary.md        #   Architecture companion
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Tree-only companion
│   ├── PROJ-HOWTO.md               #   Task guides index
│   ├── PROJ-HOWTO.summary.md       #   How-to companion
│   ├── PROJ-FAQ.md                 #   FAQ
│   ├── PROJ-FAQ.summary.md         #   FAQ companion
│   └── howto/                      #   Task-oriented deep dives
│       ├── bump-helm-values-tag.md
│       ├── diagnose-infisical-failures.md
│       ├── headless-push.md
│       └── zellij-pane-shell.md
├── CHANGELOG.md                    # Package changelog
├── Makefile                        # compile/test no-ops; install + install-completions
└── README.md                       # Start here — install, config schema, usage
```

## Key Files Requiring Setup

| File / Var | Action |
|------------|--------|
| `K8_DOCKER_REGISTRY` | Export via `.envrc.k8.dc` or environment before build/push |
| Registry login | `docker login $K8_DOCKER_REGISTRY` |
| `infra-config.yaml` / `.infra-config.yaml` | Docker targets at repo root (`project.docker.images[]` / composite `project.projects[].services[]`) |
| `~/.local/share/k8-lib/` | Shared shell library from monorepo `make install-utilities` (config, version, assist) |

## Notes

- **No `lib/`** — scripts are self-contained bash; shared logic lives in repo-level **k8-lib** (`docker-config.sh`, `docker-vsn.sh`, `assist.sh`, bash-runtime).
- **Completions**: bash → `bash-completion/completions/{docker-build,docker-push}`; zsh → `zsh/site-functions/_docker-*`. No sandbox/qemu11 completions yet.
- **Runtime state** (not in package): `.docker-state/` at project root (`last`, `shadow`, `builds`, `pushes`; sandbox PIDs under `.docker-state/sandbox/`); temp compose overrides under `.tmp/docker-sandbox/`.
- **Prerequisites**: Docker + BuildKit, `docker buildx`, `yq`; sandbox also needs `kubectl` and app `docker-compose.sandbox.yaml`.
- `Makefile` `compile`/`test` are no-ops; only `install` / `install-completions` do work.
