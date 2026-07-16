# docker-utils — FAQ Summary

Question list only. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use `docker-build`/`docker-push` instead of plain `docker build`/`docker push`?
- Why does `docker-push` need Infisical at all — can't I just tag with `docker tag`?
- Why is build state (`.docker-state/`) a thing instead of just chaining `docker-build && docker-push`?

## Fit
- When should I use `--native` instead of the default multi-arch build?
- Why does a multi-target `docker-build` take over panes in my zellij tab instead of just running sequentially?
- When should I reach for `deploy-service` instead of `docker-build`/`docker-push` directly?

## Comparison
- Which flag makes `docker-push` write the Helm `values.yaml` tag?
- How does `docker-qemu11` differ from just letting buildx handle cross-arch emulation?

## Capability
- Can I build every configured image in one command?
- Can `docker-build` run non-interactively from a script or CI agent, with no zellij and no prompts?
- Does `--headless` suppress every confirmation prompt, including on a first release?

## Caveats
- What happens if I define one real `project.docker.images[]` entry in a config that still has legacy `docker.repos`/`docker.mappings`?
- What are the limits of the build/push state tracking?
- Is `docker-qemu11`'s registration permanent?
- Why does `docker-build --dry-run --push` skip the Infisical preflight instead of still validating credentials?

## Trust
- Where do registry credentials and version secrets actually come from?
