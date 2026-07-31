# docker-utils — FAQ

For *what this is*, see [PROJ-ARCH.md](PROJ-ARCH.md); for *how to do things*,
see [PROJ-HOWTO.md](PROJ-HOWTO.md); for *where things live*, see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## Motivation

### Why would I use `docker-build`/`docker-push` instead of plain `docker build`/`docker push`?

Because it resolves the image, tag, and multi-arch platform for you from
config instead of you retyping paths and version numbers by hand. Targets
(context, dockerfile, registry path, build args) live once in
`infra-config.yaml` keyed by a short `name`, so `docker-build backend` works
from any directory instead of `docker build -f app/backend/Dockerfile ...`
with the full path memorized. It also owns the parts plain Docker doesn't:
Infisical-resolved patch versioning, multi-arch buildx wiring, zellij
fan-out for parallel builds, and a build→push handoff via `.docker-state/`.
The trade-off is indirection — you must define a target in config before you
can build it, and understanding a failure sometimes means reading the
resolved command, not just the error.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-and-push-one-image) to do it.*

### Why does `docker-push` need Infisical at all — can't I just tag with `docker tag`?

Because the patch/sub-version number is meant to be a shared, monotonic
counter across concurrent builders and CI, not something tracked in a local
file or the repo. Infisical acts as that shared counter: prod images get
`v{MAJ}.{MIN}.{PATCH}`, non-prod get an `-{env}.{SUB}` suffix, and the next
number is fetched at push time rather than computed locally. The honest cost
is a hard runtime dependency — a broken Infisical session blocks every push,
which is why `docker-build --push` runs an Infisical preflight *before* the
build starts rather than failing after ten minutes of compiling.
→ *See [howto/diagnose-infisical-failures.md](howto/diagnose-infisical-failures.md).*

### Why is build state (`.docker-state/`) a thing instead of just chaining `docker-build && docker-push`?

Because build and push are meant to be separable in time and invocation —
you can build now, walk away, and push later (or from CI, or after review)
without re-specifying the target. `docker-push` with no arguments looks at
`.docker-state/builds` and offers your most recent build back to you. The
trade-off: this state is per checkout, so it will not follow you across a
different clone or worktree of the same project, and it's capped at the last
10 unpushed builds.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-reuse-your-last-build-when-pushing-later).*

## Fit

### When should I use `--native` instead of the default multi-arch build?

Use `--native` whenever you're iterating locally and don't need a pushable
image yet — it builds host-architecture-only and `--load`s straight into
your local Docker, which multi-arch builds structurally cannot do (buildx
can't `--load` a multi-platform manifest). Reach for the multiarch default
only when you actually intend to push; building multi-arch just to inspect
locally wastes the second platform's build time for no benefit.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-iterate-fast-on-a-single-image-locally).*

### Why does a multi-target `docker-build` take over panes in my zellij tab instead of just running sequentially?

Because parallel builds need somewhere to put per-target output, and reusing
your current tab (rather than spawning a separate session/layout) keeps you
in the shell you were already in. `docker-build` detects `$ZELLIJ`/
`$ZELLIJ_SESSION_NAME`, adds one pane per target via `zellij action
new-pane`, and `exec`s your resolved login shell into each pane once its
build finishes — so panes stay usable afterward instead of closing or
dead-ending at a bare prompt. The trade-off: this only triggers for
multi-target runs (`--all`, `--pick`, `--include a,b`) inside an active
zellij session; single-target builds never use panes, and outside zellij (or
with `--no-zellij`) it falls back to background jobs logging under
`.tmp/docker-build-logs/`.
→ *See [howto/zellij-pane-shell.md](howto/zellij-pane-shell.md).*

### When should I reach for `deploy-service` instead of `docker-build`/`docker-push` directly?

Reach for `deploy-service` (in `infra-tools`) when you want the image change
to actually reach a running cluster — it composes build, push, the Helm
values tag bump, and `helm-upgrade` into one pipeline. Use `docker-build`/
`docker-push` directly when you only want the image built and published, or
you want to bump Helm values separately (`docker-push --release`) without
triggering a deploy in the same step.

## Comparison

### Which flag makes `docker-push` write the Helm `values.yaml` tag?

`--release`, and it is the *only* one — whether you invoke it standalone
(`docker-push my-backend --release`) or via `docker-build my-backend --push
--release`. There is no separate `--update-helm` flag (older monorepo docs
referenced one, but it never existed in `bin/docker-push`; those references
have been corrected). If you came looking for a "sync values.yaml to whatever
was last pushed without bumping anything" mode, it doesn't exist; `--release`
always runs the same values-tag update tied to the push itself.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-bump-the-helm-values-tag-as-part-of-a-push).*

### How does `docker-qemu11` differ from just letting buildx handle cross-arch emulation?

Buildx already does cross-arch emulation via QEMU under the hood — the
difference is *which* QEMU. The bundled `tonistiigi/binfmt:latest` image
lags upstream QEMU releases, and older QEMU is known to mis-emulate
Elixir/BEAM builds under amd64-on-arm64. `docker-qemu11` re-registers a
newer Debian-unstable QEMU 11.x binfmt so those specific builds succeed; it
doesn't replace buildx's emulation path, it upgrades the QEMU binary
underneath it. The catch: registration needs `--privileged` and does not
survive a Docker Desktop/OrbStack VM restart, so it must be rerun after one.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-fix-elixirbeam-cross-arch-build-failures-on-arm64-hosts).*

## Capability

### Can I build every configured image in one command?

Yes — `docker-build --all` (optionally `--push`) builds every target
declared under `project.docker.images[]` or the composite `services[]`
lists, fanning out into zellij panes when zellij is available or background
jobs otherwise. This is a genuine "build the whole project" switch, not just
sugar for a loop; failures per target are reported independently rather than
aborting the whole run.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-build-or-push-every-configured-image-at-once).*

### Can `docker-build` run non-interactively from a script or CI agent, with no zellij and no prompts?

Yes, but the flag lives on `docker-push`, not `docker-build`: `docker-push
--headless` implies `--yes --no-zellij --remote` for a fully scripted push.
For builds, pass `--no-zellij` (and skip `--push`'s interactive confirm with
`--yes`/`--silent`) to get the same non-interactive behavior.
→ *See [howto/headless-push.md](howto/headless-push.md).*

### Does `--headless` suppress every confirmation prompt, including on a first release?

No, and that's deliberate — the CHANGELOG confirmation on a first release
still fires under `--headless`, but it's auto-confirmed rather than left
hanging, and the auto-confirm is logged explicitly (`(headless:
auto-confirming first release)`) so a scripted push doesn't silently create a
changelog entry no one reviewed. Everything else `--headless` implies
(`--yes --no-zellij --remote`) genuinely suppresses prompts; this one
survives on purpose because skipping it silently would be a worse failure
mode than logging the auto-confirmation.
→ *See [howto/headless-push.md](howto/headless-push.md).*

## Caveats

### Why does `docker-build --dry-run --push` skip the Infisical preflight instead of still validating credentials?

Because the preflight is gated on `--push` *and not* `--dry-run` together —
`--dry-run` is meant to show the resolved plan with zero side effects and
zero network calls, and hitting Infisical to validate auth is itself a
side-effecting call worth skipping. The honest cost: a `--dry-run --push`
that looks clean tells you nothing about whether the real push would pass
the Infisical preflight — drop `--dry-run` if you actually want to exercise
that check.
→ *See [howto/diagnose-infisical-failures.md](howto/diagnose-infisical-failures.md).*

### What happens if I define one real `project.docker.images[]` entry in a config that still has legacy `docker.repos`/`docker.mappings`?

The legacy fallback stops being consulted entirely, for every target, not
just the one you added. Legacy `docker.repos`/`docker.mappings` are only
read when *no* `project:` Docker targets are discovered at all — so a
partial migration silently orphans every target you haven't yet ported to
the `project:` model. Migrate all targets in one pass, not incrementally.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-add-a-new-image-target-to-the-config).*

### What are the limits of the build/push state tracking?

It's local, capped, and non-portable: `.docker-state/` lives at the project
root of the checkout that ran the build, `builds`/`pushes` each cap at the
last 10 entries, and none of it is shared across a different clone or
worktree of the same repo. Don't rely on it as an audit trail or across
machines — it's a convenience cache for "what did I just build here,"
nothing more.

### Is `docker-qemu11`'s registration permanent?

No — it's explicitly transient. It must be rerun after every Docker Desktop
or OrbStack VM restart, because the binfmt registration lives in the VM, not
on the host filesystem. If cross-arch Elixir/BEAM builds that used to work
suddenly fail again after a restart, this is the first thing to re-run
before suspecting a code regression.

## Trust

### Where do registry credentials and version secrets actually come from?

Not from this repo. Registry/credential values are expected in
`.envrc.k8.dc` (direnv-config) at the monorepo root, and Infisical holds the
patch-version counters — `docker-utils` only reads them at runtime via
k8-lib. Nothing here stores or embeds credentials or version state in the
`docker-utils` package itself.
