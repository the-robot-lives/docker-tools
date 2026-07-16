# docker-utils — How To (summary)

Companion index to [PROJ-HOWTO.md](PROJ-HOWTO.md) — task list only, no steps.

- **Install the tools** — get `docker-build`, `docker-push`, `docker-qemu11` on your `$PATH`.
- **Build and push one image** — produce and publish a Docker image for a configured target.
- **Iterate fast on a single image locally** — rebuild quickly for the host architecture only, without pushing.
- **Build or push every configured image at once** — rebuild/republish the whole project's images in one command.
- **Run parallel builds inside your current zellij tab, in your shell** — reuse your open zellij tab and keep your login shell in each pane instead of a bare bash. → [howto/zellij-pane-shell.md](howto/zellij-pane-shell.md)
- **Push non-interactively from a script or agent** — push without any prompts, zellij, or local-only assumptions. → [howto/headless-push.md](howto/headless-push.md)
- **Preview a build/push without doing anything** — see the resolved target(s), version, and command that *would* run.
- **Fix Elixir/BEAM cross-arch build failures on arm64 hosts** — stop amd64-emulated Elixir/BEAM builds from failing under QEMU.
- **Add a new image target to the config** — make a new service buildable/pushable by name.
- **Bump the Helm values tag as part of a push** — update the Helm chart's `image.tag` to match the version you just pushed, in the same step. → [howto/bump-helm-values-tag.md](howto/bump-helm-values-tag.md)
- **Reuse your last build when pushing later** — run `docker-push` from any directory and have it recall what you just built.
- **Diagnose Infisical preflight failures** — turn an opaque "authentication failed" during `--push` into an actionable fix. → [howto/diagnose-infisical-failures.md](howto/diagnose-infisical-failures.md)
