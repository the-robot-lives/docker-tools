# merge-notes — sep-1 branch sweep (2026-09-01)

DevOps docker utility (dual-path checkout). Swept per the 2026-09-01 branch-sweep recipe (session 58fc679b).

- **Base**: `origin/main` @30027d0 (2026-08-18) — freshest tip among origin/develop / origin/main / origin/mono-repo-dev by commit date.
- **sep-1 tag**: created@30027d0 (points at base tip).
- **develop**: created@30027d0 — trunk going forward; local main fast-forwarded to origin: no.

## Review/merge sequence
1. No open PRs and no consolidation needed for this repo — nothing to merge. `develop` is the trunk; future work branches from it.

## Skip/ignore list
- `mono-repo-dev` — stale mono-repo-era snapshot, local=remote @dbfcc35, unmerged. Left intact by policy; safe to ignore, do not merge without a reconciliation pass.
- No merged branches to prune.

## Open PRs
| # | branch | base | what |
|---|--------|------|------|
| — | none | — | no open PRs in this repo |
