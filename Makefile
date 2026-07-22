INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: compile test install install-completions

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in docker-build docker-push docker-qemu11; do \
		install -m 755 "bin/$$f" "$(INSTALL_DIR)/$$f"; \
		echo "✓ Installed $$f"; \
	done
	@$(MAKE) install-completions

install-completions:
	@DATA_DIR="$${XDG_DATA_HOME:-$$HOME/.local/share}"; \
	BASH_DIR="$$DATA_DIR/bash-completion/completions"; \
	ZSH_DIR="$$DATA_DIR/zsh/site-functions"; \
	if ! mkdir -p "$$BASH_DIR" "$$ZSH_DIR" 2>/dev/null; then \
		echo "docker-utils: cannot write completion dirs; skipping."; \
		exit 0; \
	fi; \
	cp completions/docker-build.bash "$$BASH_DIR/docker-build"; \
	cp completions/docker-push.bash "$$BASH_DIR/docker-push"; \
	cp completions/_docker-build "$$ZSH_DIR/_docker-build"; \
	cp completions/_docker-push "$$ZSH_DIR/_docker-push"; \
	echo "docker-utils: completions installed (bash-completion + zsh)"; \
	if ! grep -qs "zsh/site-functions" "$$HOME/.zshrc" 2>/dev/null; then \
		echo "docker-utils: zsh users — add to .zshrc before compinit:"; \
		echo "  fpath=($$ZSH_DIR \$$fpath)"; \
	fi
