#!/bin/bash
# Procura segredos óbvios nos arquivos versionados e nos novos (não ignorados).
# Falso positivo: acrescente "# secrets-ok" na linha. Uso: bash tests/secrets.sh
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$repo" || exit 1

# IPv4 fora de faixas privadas, loopback e documentação.
ipv4='([0-9]{1,3}\.){3}[0-9]{1,3}'
private='^(0|10|127|169\.254|172\.(1[6-9]|2[0-9]|3[01])|192\.168|192\.0\.2|198\.51\.100|203\.0\.113|255)\.'
patterns=(
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'AKIA[0-9A-Z]{16}'
    '\.pem($|[^A-Za-z0-9])'
    '(^|[^-A-Za-z0-9_])(password|passwd|secret|token|api[_-]?key)[[:space:]]*[=:][[:space:]]*["'\'']?[A-Za-z0-9/+_.-]{8,}'
)

found=0
report() { printf '%s\n' "$1"; found=1; }

for pattern in "${patterns[@]}"; do
    out=$(git grep -nIiE --untracked -e "$pattern" -- . ':!tests/secrets.sh' 2>/dev/null |
        grep -v 'secrets-ok')
    [ -z "$out" ] || report "$out"
done

dns='^(8\.8\.8\.8|8\.8\.4\.4|1\.1\.1\.1|1\.0\.0\.1|9\.9\.9\.9)$'
out=$(git grep -nIE --untracked -e "$ipv4" -- . ':!tests/secrets.sh' 2>/dev/null |
    grep -v 'secrets-ok' |
    while IFS=: read -r file line text; do
        while IFS= read -r ip; do
            IFS=. read -r a b c d <<< "$ip"
            [ "$a" -le 255 ] && [ "$b" -le 255 ] && [ "$c" -le 255 ] && [ "$d" -le 255 ] || continue
            [[ "$ip" =~ $private ]] && continue
            [[ "$ip" =~ $dns ]] && continue
            printf '%s:%s: IP público %s\n' "$file" "$line" "$ip"
        done < <(grep -oE "$ipv4" <<< "$text")
    done)
[ -z "$out" ] || report "$out"

if [ "$found" -ne 0 ]; then
    printf '\nPossíveis segredos acima. Revise ou marque a linha com "# secrets-ok".\n' >&2
    exit 1
fi
echo 'secrets: nada suspeito'
