#!/bin/bash
# Testes dos helpers Bash, com HOME temporário. Uso: bash tests/bash.sh
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

check() { # descrição, esperado, obtido
    if [ "$2" = "$3" ]; then
        printf 'ok   %s\n' "$1"
    else
        printf 'FAIL %s\n  esperado: %s\n  obtido:   %s\n' "$1" "$2" "$3"
        fail=1
    fi
}

export HOME="$tmp/home"
mkdir -p "$HOME/.ssh"
cat > "$HOME/.ssh/config" <<'CFG'
Include extra.conf
Host * !wild
	User x
Host alpha beta
	Hostname a.example
CFG
printf 'Host gamma\n\tHostname g.example\n' > "$HOME/.ssh/extra.conf"

# shellcheck source=../dot.bash_functions
source "$repo/dot.bash_functions"

have bash; check 'have: comando existente' 0 $?
have comando-que-nao-existe; check 'have: comando ausente' 1 $?

export MYSERVERS="delta alpha"
check 'ssh-list: config, Include e MYSERVERS, sem curingas' \
    'alpha beta delta gamma' "$(ssh-list | tr '\n' ' ' | sed 's/ $//')"

check '_ps1-git: fora de repositório' '' "$(cd "$tmp" && _ps1-git)"
git init -q -b main "$tmp/repo"
check '_ps1-git: dentro de repositório' ' (main)' "$(cd "$tmp/repo" && _ps1-git)"

# packages.list: cada linha de dados tem 5 campos
bad=$(awk -F'|' '!/^#/ && NF && NF != 5 { print NR": "$0 }' "$repo/packages.list")
check 'packages.list: 5 campos por linha' '' "$bad"

exit "$fail"
