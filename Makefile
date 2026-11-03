SHELL := /bin/bash
.DEFAULT_GOAL := help

# Keep the path intact when Makefile is invoked with -f and contains spaces.
export DOTFILES_MAKEFILE := $(MAKEFILE_LIST)

.PHONY: help dry-run install status uninstall check install-hooks

# Alvos documentados com "## descrição" aparecem aqui automaticamente.
help: ## Exibe esta ajuda (padrão).
	@printf 'Uso: make [alvo]\n'
	@awk -F':.*## ' '/^[a-z][a-z-]*:.*## / { printf "  %-14s %s\n", $$1, $$2 }' \
		$(firstword $(MAKEFILE_LIST))

dry-run: ## Mostra os comandos sem alterar arquivos.
install: ## Instala com saída detalhada e preserva configurações locais existentes.

# Lista "origem<TAB>destino" dos links. Mantenha em sincronia com o loop de dry-run/install.
define LINKS_FN
links() { \
	local dot name; \
	for dot in "$$1"/dot.*; do \
		[ -e "$$dot" ] || continue; \
		name=$${dot##*/}; \
		case "$$name" in dot.config|*.local) continue;; esac; \
		printf '%s\t%s\n' "$$dot" "$$HOME/.$${name#dot.}"; \
	done; \
	printf '%s\t%s\n' "$$1/ssh/config" "$$HOME/.ssh/config"; \
}
endef
export LINKS_FN

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
	printf 'mkdir -p %q %q\n' "$$HOME/.ssh/sessions" "$$HOME/bin/$$os"; \
	if [ "$$mode" != dry-run ]; then \
		mkdir -p "$$HOME/.ssh/sessions" "$$HOME/bin/$$os"; \
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


status: ## Mostra o estado dos links em HOME (ok, quebrado, arquivo real ou ausente).
	@set -e; \
	read -r makefile <<< "$$DOTFILES_MAKEFILE"; \
	repo=$$(cd -- "$$(dirname -- "$$makefile")" && pwd -P); \
	eval "$$LINKS_FN"; \
	bad=0; \
	while IFS=$$'\t' read -r from to; do \
		if [ -L "$$to" ]; then \
			cur=$$(readlink "$$to"); \
			if [ "$$cur" = "$$from" ] && [ -e "$$to" ]; then state=ok; \
			elif [ ! -e "$$to" ]; then state="quebrado -> $$cur"; \
			else state="outro destino -> $$cur"; fi; \
		elif [ -e "$$to" ]; then state='arquivo real (não é link)'; \
		else state=ausente; fi; \
		[ "$$state" = ok ] || bad=1; \
		printf '%-24s %s\n' "$$state" "$$to"; \
	done < <(links "$$repo"); \
	exit $$bad

# DRY_RUN=1 apenas mostra o que seria removido.
uninstall: ## Remove os links que apontam para este repositório (DRY_RUN=1 simula).
	@set -e; \
	read -r makefile <<< "$$DOTFILES_MAKEFILE"; \
	repo=$$(cd -- "$$(dirname -- "$$makefile")" && pwd -P); \
	eval "$$LINKS_FN"; \
	while IFS=$$'\t' read -r from to; do \
		if [ -L "$$to" ] && [ "$$(readlink "$$to")" = "$$from" ]; then \
			printf 'rm %q\n' "$$to"; \
			[ -n "$(DRY_RUN)" ] || rm "$$to"; \
		else \
			printf 'Preservado: %s\n' "$$to"; \
		fi; \
	done < <(links "$$repo")

check: ## Valida sintaxe (bash -n), ShellCheck e testes, quando disponíveis.
	@set -e; \
	read -r makefile <<< "$$DOTFILES_MAKEFILE"; \
	repo=$$(cd -- "$$(dirname -- "$$makefile")" && pwd -P); \
	cd "$$repo"; \
	files=$$(ls dot.bash* local/*.example tests/bash.sh 2>/dev/null || true); \
	for f in $$files; do bash -n "$$f"; done; \
	printf 'bash -n: %s arquivos ok\n' "$$(echo "$$files" | wc -w | tr -d ' ')"; \
	if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -s bash -S warning $$files; \
		$(MAKE) --no-print-directory -n install | shellcheck -s bash -S warning -; \
		echo 'shellcheck: ok'; \
	else \
		echo 'shellcheck: não instalado, ignorado'; \
	fi; \
	if [ -f tests/bash.sh ]; then bash tests/bash.sh; fi

install-hooks: ## Instala o pre-commit que executa "make check".
	@set -e; \
	read -r makefile <<< "$$DOTFILES_MAKEFILE"; \
	repo=$$(cd -- "$$(dirname -- "$$makefile")" && pwd -P); \
	hook=$$(git -C "$$repo" rev-parse --git-path hooks)/pre-commit; \
	case "$$hook" in /*) ;; *) hook="$$repo/$$hook";; esac; \
	if [ -e "$$hook" ] && ! grep -q 'dotfiles make check' "$$hook"; then \
		printf 'Refusing to overwrite existing hook: %s\n' "$$hook" >&2; exit 1; \
	fi; \
	printf '#!/bin/bash\n# dotfiles make check\nexec make --no-print-directory -C %q check\n' "$$repo" > "$$hook"; \
	chmod +x "$$hook"; \
	printf 'Instalado: %s\n' "$$hook"
