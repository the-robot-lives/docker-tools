# Project Layout — Summary

Docker build/push/sandbox/QEMU terminal utilities for the Noizu k8s toolchain.
Full annotated tree: [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

```
docker-utils/
├── bin/                        # docker-build · docker-push · docker-sandbox · docker-qemu11
├── completions/                # bash + zsh for docker-build / docker-push
├── docs/
│   ├── PROJ-ARCH.md · PROJ-ARCH.summary.md
│   ├── PROJ-LAYOUT.md · PROJ-LAYOUT.summary.md
│   ├── PROJ-HOWTO.md · PROJ-HOWTO.summary.md
│   ├── PROJ-FAQ.md · PROJ-FAQ.summary.md
│   └── howto/                  # helm-tag, infisical, headless-push, zellij-pane
├── CHANGELOG.md
├── Makefile                    # make install → ~/.local/bin + completions
└── README.md
```
