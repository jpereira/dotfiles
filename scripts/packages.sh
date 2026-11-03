#!/bin/bash
# Verifica e instala as dependências listadas em packages.list (macOS com brew, Linux com apt).
# Compatível com Bash 3.2.
set -u
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
list="$repo/packages.list"

usage() {
    cat <<'USAGE'
Uso: scripts/packages.sh [comando] [opções]
  check      Mostra o que está instalado e o que falta (padrão). Sai com 1 se faltar "base".
  install    Instala o que falta.
  list       Mostra o que seria instalado, sem instalar.
Opções:
  -g GRUPOS  Grupos separados por vírgula (padrão: base,visual; "all" inclui extras)
  -n         Simula: imprime os comandos sem executar
  -y         Não pergunta antes de instalar
USAGE
}

cmd=check groups=base,visual dry=0 yes=0
if [ $# -gt 0 ]; then
    case "$1" in check|install|list) cmd=$1; shift;; esac
fi
while getopts g:nyh opt; do
    case "$opt" in
        g) groups=$OPTARG;;
        n) dry=1;;
        y) yes=1;;
        *) usage; exit 2;;
    esac
done
[ "$groups" != all ] || groups=base,visual,extras

case "${DOTFILES_PKG_MANAGER:-$(uname -s)}" in
    apt) manager=apt;;
    brew) manager=brew;;
    Darwin) manager=brew;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then manager=apt
        elif command -v brew >/dev/null 2>&1; then manager=brew
        else manager=; fi;;
    *) manager=;;
esac
if [ -z "$manager" ] || { [ "$manager" = brew ] && ! command -v brew >/dev/null 2>&1; }; then
    if [ "$cmd" = install ]; then
        echo 'Gerenciador de pacotes não encontrado (brew ou apt-get).' >&2
        exit 1
    fi
fi

installed() { # "a b @/arquivo" -> 0 se algum comando ou arquivo existir
    local c
    for c in $1; do
        case "$c" in
            @*) [ -f "${c#@}" ] && return 0;;
            *) command -v "$c" >/dev/null 2>&1 && return 0;;
        esac
    done
    return 1
}

label() { # primeiro item legível do campo comandos
    local c=${1%% *}
    case "$c" in @*) basename "${c#@}" ;; *) echo "$c";; esac
}

missing=() manual=() base_missing=0
[ "$cmd" = list ] || printf '%-8s %-18s %s\n' GRUPO COMANDO ESTADO
while IFS='|' read -r group commands brew_pkg apt_pkg desc; do
    case "$group" in ''|'#'*) continue;; esac
    case ",$groups," in *",$group,"*) ;; *) continue;; esac
    if installed "$commands"; then
        state='ok'
    else
        state='falta'
        [ "$group" != base ] || base_missing=1
        pkg=$brew_pkg
        [ "$manager" = apt ] && pkg=$apt_pkg
        if [ "$pkg" = - ] || [ -z "$manager" ]; then
            manual+=("$(label "$commands") ($desc)")
            state='falta (instalar à mão)'
        else
            missing+=("$pkg")
        fi
    fi
    [ "$cmd" = list ] || printf '%-8s %-18s %s\n' "$group" "$(label "$commands")" "$state"
done < "$list"

[ "$cmd" = list ] || echo
if [ "$cmd" != list ] && [ "${#manual[@]}" -gt 0 ]; then
    echo 'Sem pacote neste sistema:'
    printf '  - %s\n' "${manual[@]}"
fi

case "$cmd" in
    check)
        [ "${#missing[@]}" -eq 0 ] || echo "Instale com: make packages-install   (ou scripts/packages.sh install)"
        exit "$base_missing";;
    list)
        [ "${#missing[@]}" -eq 0 ] || printf '%s\n' "${missing[@]}"
        exit 0;;
esac

[ "${#missing[@]}" -gt 0 ] || { echo 'Nada a instalar.'; exit 0; }
case "$manager" in
    brew) install=(brew install "${missing[@]}");;
    apt)
        install=(apt-get install -y "${missing[@]}")
        [ "$(id -u)" -eq 0 ] || install=(sudo "${install[@]}");;
esac
printf '+'; printf ' %q' "${install[@]}"; echo
[ "$dry" -eq 0 ] || exit 0
if [ "$yes" -eq 0 ]; then
    read -r -p 'Instalar agora? [s/N] ' answer
    case "$answer" in s|S|y|Y) ;; *) echo 'Cancelado.'; exit 1;; esac
fi
"${install[@]}"
