# Threat Model — Summary

Single-user developer-workstation tooling; crown jewels are borrowed
credentials: registry push creds, Infisical token (write authority over shared
`docker-versions/*` keys, CI-shared), and the kubeconfig reaching prod
services. No server component, no database.

## Trust Boundaries

1. Project repos being built ↔ tooling shell (repo content partially *executed*)
2. Workstation ↔ Docker daemon (buildx + one privileged container)
3. Workstation ↔ container registry (docker credential store)
4. Workstation ↔ Infisical (TLS + CF Access; token via env to children)
5. Workstation ↔ k8s API (port-forward of prod DB/Redis to loopback)
6. Sandbox containers ↔ host network (`host.docker.internal:host-gateway`)

## Register (7)

| ID | Sev | Component | Status |
|----|-----|-----------|--------|
| T-001 | Medium | `docker-hooks.sh` auto-sourced from project root | Open (trusted-repos policy) |
| T-002 | Medium | bash-sourced `.docker-state/` files | Partial |
| T-003 | High | sandbox containers bridged to loopback-forwarded prod DB/Redis | Partial |
| T-004 | Medium | Infisical/CF Access token in child env | Partial |
| T-005 | Low | privileged QEMU installer from mutable tag | Open (pin image) |
| T-006 | Medium | `--release` rewrites helm values tag locally | Mitigated |
| T-007 | Low | unredacted error bodies / build logs | Partial |

Coverage: 1 mitigated · 4 partial · 2 open. First registered model 2026-10-26.
