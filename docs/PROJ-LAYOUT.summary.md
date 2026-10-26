# Project Layout — Summary

```
docker-utils/
├── bin/                        # Executable utilities
│   ├── docker-build            #   Build configured Docker image targets
│   ├── docker-push             #   Push images w/ Infisical patch versioning
│   ├── docker-sandbox          #   Sandbox against forwarded prod services
│   └── docker-qemu11           #   Register QEMU 11.x binfmt (amd64 on arm)
├── completions/                # bash + zsh completions (docker-build, docker-push)
├── docs/                       # PROJ-* / THREAT-MODEL docs + howto/ runbooks
├── .gitignore                  # .DS_Store, swap files, .env, .envrc.local, .claude/worktrees/
├── AGENT.md                    # Agent guidance (Codex/Grok/Cursor)
├── AGENTS.md                   # Agent guidance (numbered-MUST form)
├── CHANGELOG.md
├── CLAUDE.md                   # Claude Code agent guidance
├── Makefile                    # make install → ~/.local/bin + completions
├── README.md                   # Install, config sources, target schema
└── merge-notes.md
```

Runtime state (gitignored): `.docker-state/`, `.tmp/docker-sandbox/` at the infra-config root.
