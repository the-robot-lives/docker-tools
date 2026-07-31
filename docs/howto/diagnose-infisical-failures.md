# How to: diagnose Infisical preflight failures

**Goal:** turn an opaque "authentication failed" during `--push` into an
actionable fix.
**Prereqs:** none — this is the failure path itself.

1. Reproduce and read the full diagnostic; `--push` runs `_infisical_preflight`
   before any build/push work starts, and failures now print HTTP status,
   captured `curl` stderr, and the response body instead of a bare message:
   ```bash
   docker-build my-backend --push
   ```
2. Match the failure to its cause:
   - `❌ Infisical preflight: INFISICAL_HOST is not set` — source `.envrc` or
     set `k8.infisical.host` / `secrets.infisical.host` in the merged config.
   - `❌ Infisical preflight: operator credentials not set` — set
     `EKS_OPERATOR_CLIENT_ID` and `EKS_OPERATOR_CLIENT_SECRET` (via
     `.envrc.k8.dc`, not committed values).
   - `❌ Infisical preflight: authentication failed (HTTP ###)` — the printed
     HTTP status + body identify whether it's bad credentials (401), a
     network/CF-Access block (403/000), or a server error (5xx).
3. If Cloudflare Access headers are involved, confirm `cf access.client_id` /
   `cf access.client_secret` resolve — a missing pair means requests go out
   with no `CF-Access-Client-*` headers and get blocked at the edge before
   Infisical ever sees them.

**Verify:** rerun `docker-build my-backend --push` (without `--dry-run`) — the
preflight step alone should now report `✅ Authenticated` before any build
work starts.

**Gotchas:**
- The preflight step runs once and its resolved token/project/creds are
  reused by the `docker-push` it spawns — if you're debugging by running
  `docker-push` directly instead of through `docker-build --push`, make sure
  you're testing the same credential path (`docker-push` runs its own
  preflight when invoked standalone).
- `--dry-run` **skips** the Infisical preflight entirely (it's gated on
  `--push` AND not `--dry-run`), so it won't surface these failures — drop
  `--dry-run` to actually exercise the preflight step.
