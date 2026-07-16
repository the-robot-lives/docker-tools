# How to: push non-interactively from a script or agent

**Goal:** push a built image with zero prompts, zero zellij, zero
local-only assumptions — safe for CI, cron, or an agent driving the shell.

**Prereqs:** target already built (or buildable), Infisical operator
credentials reachable non-interactively (`EKS_OPERATOR_CLIENT_ID`/
`EKS_OPERATOR_CLIENT_SECRET` resolvable via `.envrc.k8.dc` or env).

1. ```bash
   docker-push my-backend --headless
   ```
   `--headless` is shorthand for `--yes --no-zellij --remote`: it
   auto-confirms prompts, skips zellij panes, and treats the push as a
   remote/scripted run.
2. To build-then-push headlessly in one shot, pass the same flag through
   `docker-build`:
   ```bash
   docker-build my-backend --push --headless
   ```
   `docker-build` forwards `--headless` to the `docker-push` it invokes.

**Verify:** the command exits non-interactively with a success/failure
status and no prompt is ever printed; check `$?` (or your CI job's exit
code) rather than watching for a confirmation line.

**Gotchas:**
- One prompt survives `--headless` on purpose: the CHANGELOG confirmation
  on a first release is still auto-confirmed, but is logged explicitly
  (`(headless: auto-confirming first release)`) — check logs if a scripted
  push produced an unexpected changelog entry.
- `--headless` implies `--remote`; don't also assume `--native`/local-only
  build behavior — combine explicitly with `docker-build --native` if you
  need single-arch local images pushed headlessly.
- If Infisical auth fails under `--headless`, there's no prompt to retry —
  see [diagnose-infisical-failures.md](diagnose-infisical-failures.md).
