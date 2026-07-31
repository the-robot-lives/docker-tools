# How to: run parallel builds inside your current zellij tab, in your shell

**Goal:** when building multiple targets (`--all`, `--pick`, `--include a,b`),
get one zellij pane per target added to the tab you're already in, each
running your actual login shell instead of a bare `bash`.

**Prereqs:** zellij session running; more than one build target selected
(single-target builds don't spawn panes).

1. Just run a multi-target build from inside an active zellij session:
   ```bash
   docker-build --all
   ```
   `docker-build` detects `$ZELLIJ`/`$ZELLIJ_SESSION_NAME` and adds panes to
   the current tab via `zellij action new-pane` instead of spawning a new
   session/layout.
2. Each pane resolves a shell in this order and `exec`s into it once the
   build command finishes, so the pane stays open and usable:
   - `$DOCKER_BUILD_PANE_SHELL` if set
   - the parent process's shell (auto-detected)
   - `$SHELL`
   - `/bin/bash` as last resort
3. Override the shell explicitly if auto-detection guesses wrong:
   ```bash
   DOCKER_BUILD_PANE_SHELL=/bin/zsh docker-build --all
   ```

**Verify:** after the build panes finish, each one drops you into an
interactive shell (your configured one, not a bare `bash`) rather than
closing or sitting at a dead prompt.

**Gotchas:**
- Pane commands are shell-escaped (`_kdl_escape`) before being written into
  the generated KDL layout, so image names/paths with spaces or special
  characters won't corrupt the layout — this was a real bug prior to
  `m3-zellij-panes`.
- No zellij session detected, or you pass `--no-zellij`: builds fall back to
  background jobs with logs under `.tmp/docker-build-logs/` instead of panes.
- Single-target builds never use panes/zellij at all, regardless of shell.
