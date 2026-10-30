SHELL := /bin/bash
.DEFAULT_GOAL := help

# Keep the path intact when Makefile is invoked with -f and contains spaces.
export DOTFILES_MAKEFILE := $(MAKEFILE_LIST)

.PHONY: help dry-run install

help:
	@printf '%s\n' \
		'Uso: make [help|dry-run|install]' \
		'  help     Exibe esta ajuda (padrão).' \
		'  dry-run  Mostra os comandos sem alterar arquivos.' \
		'  install  Instala com saída detalhada e preserva configurações locais existentes.'

# A single Bash process keeps functions and variables available throughout the recipe.
# ln -n replaces a directory symlink itself, without adding links inside its target.
dry-run install:
	@set -e; \
	read -r makefile <<< "$$DOTFILES_MAKEFILE"; \
	repo=$$(cd -- "$$(dirname -- "$$makefile")" && pwd -P); \
	mode='$@'; \
	os=$$(uname -s); \
	case "$$os" in Linux|Darwin) ;; *) echo "Unsupported OS: $$os" >&2; exit 1;; esac; \
	install-link() { \
		local from="$$1" to="$$2"; \
		if [ -d "$$to" ] && [ ! -L "$$to" ]; then \
			printf 'Refusing to replace directory: %s\n' "$$to" >&2; \
			return 1; \
		fi; \
		printf 'ln -sfn %q %q\n' "$$from" "$$to"; \
		if [ "$$mode" != dry-run ]; then \
			ln -sfn "$$from" "$$to"; \
		fi; \
	}; \
	for dot in "$$repo"/dot.*; do \
		[ -e "$$dot" ] || continue; \
		name=$${dot##*/}; \
		case "$$name" in \
			dot.config|*.local) printf 'Ignorado: %s\n' "$$dot"; continue;; \
		esac; \
		install-link "$$dot" "$$HOME/.$${name#dot.}"; \
	done; \
	printf 'mkdir -p %q %q\n' "$$HOME/.ssh" "$$HOME/bin/$$os"; \
	if [ "$$mode" != dry-run ]; then \
		mkdir -p "$$HOME/.ssh" "$$HOME/bin/$$os"; \
	fi; \
	install-link "$$repo/ssh/config" "$$HOME/.ssh/config"; \
	for name in bash_profile.local bash_alias.local; do \
		from="$$repo/local/$$name.example"; \
		to="$$HOME/.$$name"; \
		[ -f "$$from" ] || continue; \
		if [ -e "$$to" ] || [ -L "$$to" ]; then \
			printf 'Preservado: %s (já existe)\n' "$$to"; \
			continue; \
		fi; \
		printf 'cp -n %q %q\n' "$$from" "$$to"; \
		if [ "$$mode" != dry-run ]; then \
			cp -n "$$from" "$$to"; \
		fi; \
	done; \
	if [ "$$os" = Darwin ]; then \
		if [ -e "$$HOME/.lldb" ]; then \
			printf 'Preservado: %s (já existe)\n' "$$HOME/.lldb"; \
		else \
			printf 'git clone https://github.com/jpereira/lldbinit %q\n' "$$HOME/.lldb"; \
			if [ "$$mode" != dry-run ]; then \
				git clone https://github.com/jpereira/lldbinit "$$HOME/.lldb"; \
			fi; \
		fi; \
	fi
