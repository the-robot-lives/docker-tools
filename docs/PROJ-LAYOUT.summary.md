# Project Layout — Summary

```
docker-utils/
├── bin/                        # Executable utilities
│   ├── docker-build            #   Build configured Docker image targets
│   ├── docker-push             #   Push images w/ Infisical patch versioning
│   └── docker-qemu11           #   Register QEMU 11.x binfmt (amd64 on arm)
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
├── .gitignore                  # Editor swap files, .env, .envrc.local
├── Makefile                    # make install → ~/.local/bin
└── README.md                   # Install, config sources, target schema
```
