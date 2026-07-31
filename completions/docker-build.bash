# bash completion for docker-build.
#
# Install (either works):
#   1. Copy to ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/docker-build
#      (done by `make install-completions`; auto-loaded by bash-completion v2).
#   2. Source this file from .bashrc.

__docker_build_image_keys() {
    local f="$PWD"
    # Walk up from $PWD to the repo root (first dir holding .infra-config.yaml).
    # Guard: missing yq or config ⇒ emit nothing.
    while [[ "$f" != "/" ]]; do
        if [[ -f "$f/.infra-config.yaml" ]]; then
            yq '.project.projects[].services[].name, .project.docker.images[].name' "$f/.infra-config.yaml" 2>/dev/null | sort -u
            return
        fi
        f="${f%/*}"
    done
}

_docker_build() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()

    # Flags whose value is the next word.
    case "$prev" in
        --env)        COMPREPLY=($(compgen -W "dev stage prod" -- "$cur")); return ;;
        --platform)   COMPREPLY=($(compgen -W "linux/amd64 linux/arm64 linux/amd64,linux/arm64" -- "$cur")); return ;;
        --vsn)        return ;;
        --config)     COMPREPLY=($(compgen -f -- "$cur")); return ;;
        --include)    COMPREPLY=($(compgen -W "$(__docker_build_image_keys)" -- "$cur")); return ;;
    esac

    # Handle --flag= forms (bash-completion passes the whole token as cur).
    case "$cur" in
        --env=*)      COMPREPLY=($(compgen -W "dev stage prod" -P "--env=" -- "${cur#--env=}")); return ;;
        --config=*)   COMPREPLY=($(compgen -f -P "--config=" -- "${cur#--config=}")); return ;;
        --include=*)  COMPREPLY=($(compgen -W "$(__docker_build_image_keys)" -P "--include=" -- "${cur#--include=}")); return ;;
        --vsn=*)      return ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--silent --push --dry-run -up --verbose -v --yes -y --all --pick --dev --stage --prod --env --no-buildx --no-cache --no-zellij --release --native --multiarch --platform --vsn --publish-chart --no-publish-chart --config --include -h --help" -- "$cur"))
        return
    fi

    # Positional: one image key.
    COMPREPLY=($(compgen -W "$(__docker_build_image_keys)" -- "$cur"))
}

complete -F _docker_build docker-build
