# Bash 3.2+ helpers, sorted by name. Optional tools are required only when called.

# Used to locate the annotated files even after changing directories.
_DOTFILES_HELP_SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}"

# @help Verifica comandos necessários e informa a primeira dependência ausente.
# @syntax _dotfiles-require <função> <comando> [...]
_dotfiles-require() {
    local caller="$1" dependency
    shift
    for dependency in "$@"; do
        if [ "$dependency" = "$caller" ]; then
            type -P "$dependency" >/dev/null 2>&1 && continue
        else
            command -v "$dependency" >/dev/null 2>&1 && continue
        fi
        printf '%s: comando %s não encontrado\n' "$caller" "$dependency" >&2
        return 127
    done
}

# @help Edita arquivo com EDITOR e EDITOR_OPTS; pode recarregar o shell.
# @syntax _edit-config <arquivo> [reload]
_edit-config() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file="$1" reload="${2:-}"
    local -a editor options
    [ -f "$file" ] || { printf 'File not found: %s\n' "$file" >&2; return 1; }
    read -r -a editor <<< "${EDITOR:-vim}"
    read -r -a options <<< "${EDITOR_OPTS:-}"
    _dotfiles-require "${FUNCNAME[0]}" "${editor[0]}" || return
    "${editor[@]}" "${options[@]}" "$file" || return
    if [ -n "$reload" ]; then
        source "$HOME/.bashrc"
    fi
}

# @help Branch (ou hash) git para o PS1, no formato " (nome)"; vazio fora de repositório.
# @syntax _ps1-git
_ps1-git() {
    local ref
    ref=$(git symbolic-ref --quiet --short HEAD 2>/dev/null ||
        git rev-parse --short HEAD 2>/dev/null) || return 0
    printf ' (%s)' "$ref"
}

# @help Cria atalhos cd.*; caracteres especiais no nome viram _.
# @syntax _set-dir2alias <diretório>
_set-dir2alias() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local path="$1" name dir child quoted
    [ -d "$path" ] || return 0
    name="${path##*/}"
    name="${name%.git}"
    name=$(printf '%s' "$name" | LC_ALL=C sed 's/[^a-zA-Z0-9_.-]/_/g')
    printf -v quoted '%q' "$path"
    # Values are intentionally captured when this alias is created.
    # shellcheck disable=SC2139
    alias "cd.${name}=cd $quoted && ls -l"
    for dir in "$path"/*; do
        [ -d "$dir" ] || continue
        child=$(printf '%s' "${dir##*/}" | LC_ALL=C sed 's/[^a-zA-Z0-9_.-]/_/g')
        printf -v quoted '%q' "$dir"
        # shellcheck disable=SC2139
        alias "cd.${name}.${child}=cd $quoted && ls -l"
    done
}

# @help Cria um atalho edit-* para um arquivo.
# @syntax _set-edit2alias <arquivo> [nome]
_set-edit2alias() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file="$1" name="${2:-}" quoted
    [ -n "$name" ] || name="${file##*/}"
    name="${name#.}"
    name=$(printf '%s' "$name" | LC_ALL=C sed 's/[^a-zA-Z0-9_.-]/_/g')
    printf -v quoted '%q' "$file"
    # shellcheck disable=SC2139
    alias "edit-${name}=_edit-config $quoted"
}

# @help Limpa marcação em um arquivo AsciiDoc.
# @syntax adoc-cleanup <arquivo>
adoc-cleanup() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    local temporary
    temporary=$(mktemp "${1}.XXXXXX") || return
    if sed 's/\.\.\.\./```/g; s/``*/`/g; s/+`/`/g' "$1" > "$temporary"; then
        cat "$temporary" > "$1"
        local status=$?
        command rm -f -- "$temporary"
        return "$status"
    fi
    command rm -f -- "$temporary"
    return 1
}

# @help Lista arquivos do diretório como links AsciiDoc.
# @syntax adoc-ls2link
adoc-ls2link() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file child
    for file in *; do
        [ -e "$file" ] || continue
        [ "$file" = index.adoc ] && continue
        if [ -d "$file" ]; then
            printf '* %s\n' "$file"
            for child in "$file"/*; do
                [ -e "$child" ] || continue
                printf '** link:%s[%s]\n' "$child" "${child##*/}"
            done
        else
            printf '* link:%s[%s]\n' "$file" "$file"
        fi
    done
}

# @help Calcula cenários de preço com bc; não consulta cotações.
# @syntax btc-show-price <dólar-em-reais> [quantidade-btc] [limite]
btc-show-price() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" bc || return
    local _dolar=$1 _btcs _rnd _d _p avarage _amount
    _btcs=${2:-1}
    _rnd=${3:-50}
    _d=18 # btc inicio
    local number
    for number in "$_dolar" "$_btcs"; do
        [[ $number =~ ^[0-9]+([.][0-9]+)?$ ]] || {
            echo 'Prices and quantities must be nonnegative decimal numbers.' >&2
            return 2
        }
    done
    case "$_rnd" in ''|*[!0-9]*) echo 'Rounds must be an integer.' >&2; return 2;; esac

    if [ -z "$_dolar" ]; then
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    fi

    echo "USD\$1    = BRL\$${_dolar}"
    echo "Qtd BTCs = ${_btcs}"
    echo

    while [[ $_d -lt $_rnd ]]; do
        _p=$(bc <<< "scale=4; $_d * $_dolar") || return
        avarage=""
        if [ -n "$_btcs" ]; then
            _amount=$(bc <<< "scale=4; ($_btcs * ${_p}) * 100") || return
            avarage="(${_btcs}btcs x R\$${_p} +/- R\$${_amount})"
        fi

        echo "BTC\$${_d}000 -> R\$${_p}00 $avarage"

        _d=$((_d + 2))
    done
}

# @help Calcula venda, recompra e lucro com bc.
# @syntax btc-trade-strategy <venda> <recompra> <quantidade> [acréscimo] [dólar-em-reais]
btc-trade-strategy() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" bc || return
    local _total_plus _total_sale _rebuy_total _profit _total_reais
    local _sale_price=$1
    local _rebuy_price=$2
    local _total=${3:-15}
    local _plus=${4:-0}
    local _reais=${5:-5.65}

    if [ $# -lt 3 ]; then
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    fi

    local number
    for number in "$_sale_price" "$_rebuy_price" "$_total" "$_plus" "$_reais"; do
        [[ $number =~ ^[0-9]+([.][0-9]+)?$ ]] || {
            echo 'Prices and quantities must be nonnegative decimal numbers.' >&2
            return 2
        }
    done
    _total_plus=$(echo "${_total} + ${_plus}" | bc) || return
    _total_sale=$(echo "scale=2; (${_total} * ${_sale_price})" | bc) || return
    _rebuy_total=$(echo "scale=2; (${_total_plus} * ${_rebuy_price})" | bc) || return
    _profit=$(echo "scale=2; (${_total_sale} - ${_rebuy_total})" | bc) || return
    _total_reais=$(echo "scale=2; ${_profit} * ${_reais}" | bc) || return

    echo "Estrategia BTC"
    echo " > Vendendo ${_total} bitcoins por US\$${_sale_price} = +/- US\$${_total_sale}"
    echo " > Recomprar ${_total}+${_plus}=${_total_plus} bitcoins por US\$${_rebuy_price} totalizando +/- US\$${_rebuy_total}"
    echo " > Mantendo os ${_total}+${_plus}=${_total_plus}, Embolsando lucro de US\$${_profit} (USD x R\$${_reais} +/- = R\$${_total_reais})"
}

# @help Remove arquivos de backup *~ sob o diretório atual.
# @syntax cleanup-backup-files
cleanup-backup-files() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    find "$PWD" -type f -name '*~' -exec rm -fv -- {} +
}

# @help Encerra sessões Screen desconectadas.
# @syntax cleanup-screen-sessions
cleanup-screen-sessions() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" screen || return
    local _s
    screen -ls | awk '/De/ { print $1 }' | while read -r _s; do
        echo "# ~~> screen: Removing $_s";

        screen -S "$_s" -X quit || return
        screen -wipe "$_s"
    done
}

# @help Remove revisões Snap desativadas (Linux).
# @syntax cleanup-snap
cleanup-snap() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" snap sudo || return
    local snapname revision
    snap list --all | awk '/disabled/{print $1, $3}' | \
    while read -r snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
}

# @help Remove arquivos de ~/.ssh/sessions.
# @syntax cleanup-ssh-sessions
cleanup-ssh-sessions() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file
    for file in "$HOME/.ssh/sessions"/*; do
        [ -e "$file" ] || [ -L "$file" ] || continue
        command rm -fv -- "$file" || return
    done
}

# @help Copia com progresso usando rsync.
# @syntax cp-progressbar <origem> <destino>
cp-progressbar() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 2 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" rsync || return
    command rsync -a --progress -- "$1" "$2"
}

# @help Calcula diferença em meses entre duas datas YYYYMM.
# @syntax date-months-between <YYYYMM> <YYYYMM>
date-months-between() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local first="$1" second="$2" year1 month1 year2 month2 difference
    case "$first:$second" in
        [0-9][0-9][0-9][0-9][01][0-9]:[0-9][0-9][0-9][0-9][01][0-9]) ;;
        *) dotfiles-help --exact "${FUNCNAME[0]}" >&2; return 2;;
    esac
    year1=$((10#${first:0:4})); month1=$((10#${first:4:2}))
    year2=$((10#${second:0:4})); month2=$((10#${second:4:2}))
    [ "$month1" -ge 1 ] && [ "$month1" -le 12 ] &&
        [ "$month2" -ge 1 ] && [ "$month2" -le 12 ] || return 2
    difference=$(((year2 - year1) * 12 + month2 - month1))
    printf 'diff between %s and %s: %s\n' "$first" "$second" "$difference"
}

# @help Atualiza pacotes com apt (Debian/Ubuntu).
# @syntax debian-update
debian-update() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" sudo apt || return
    sudo apt update && sudo apt -fy dist-upgrade && sudo apt -fy upgrade
}

# @var DOCKER_CONTEXT
# @help Contexto usado pelo cliente Docker, quando configurado.

# @var DOCKER_REMOTE_SERVER
# @help Identificação pessoal do servidor Docker, quando configurada.

# -h/--help are optional for interactive calls without positional arguments.
# shellcheck disable=SC2120
# @help Mostra o contexto Docker configurado.
# @syntax docker-banner
docker-banner() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    echo "#"
    echo "# DOCKER_CONTEXT=\"${DOCKER_CONTEXT}\" DOCKER_REMOTE_SERVER=\"${DOCKER_REMOTE_SERVER}\""
    echo "#"
}

# @help Limpa imagens Docker sem tag.
# @syntax docker-cleanup-containers-untagged
docker-cleanup-containers-untagged() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-cleanup-images-none
}

# -h/--help are optional for interactive calls without positional arguments.
# shellcheck disable=SC2120
# @help Remove imagens pendentes com docker image prune.
# @syntax docker-cleanup-images-none
docker-cleanup-images-none() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    docker image prune -f
}

# @help Remove todos os containers, inclusive em execução.
# @syntax docker-cleanup-instances-all
docker-cleanup-instances-all() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    local ids id
    ids=$(docker ps -aq) || return
    for id in $ids; do
        docker rm -f "$id" || return
    done
}

# @help Remove containers parados.
# @syntax docker-cleanup-instances-stopped
docker-cleanup-instances-stopped() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    docker container prune -f
}

# @help Abre Bash em um container em execução.
# @syntax docker-run-bash-in <container>
docker-run-bash-in() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    docker exec -it "$1" /bin/bash
}

# @help Cria imagem do último container e abre Bash nela.
# @syntax docker-run-prev-container
docker-run-prev-container() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    local id image
    id=$(docker ps -alq) || return
    [ -n "$id" ] || { echo 'No previous container.' >&2; return 1; }
    image="prev_container/$id"
    docker commit "$id" "$image" || return
    docker run -it --entrypoint=/bin/bash "$image"
}

# @help Lista endereços dos containers em execução.
# @syntax docker-show-ips
docker-show-ips() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    local ids id
    ids=$(docker ps -q) || return
    for id in $ids; do
        docker inspect -f \
            '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$id" || return
    done
}

# @help Para todos os containers em execução.
# @syntax docker-stop-instances
docker-stop-instances() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" docker || return
    docker-banner
    local ids id
    ids=$(docker ps -q) || return
    for id in $ids; do
        docker stop "$id" || return
    done
}

# @help Consulta funções, aliases e variáveis dos dotfiles.
# @syntax dotfiles-help [functions|aliases|vars|all|filtro]
dotfiles-help() {
    local topic="${1:-}" filter='' kind name description syntax definition value exact=0
    if [ "$topic" = --exact ]; then
        exact=1
        topic="${2:-}"
    fi
    local directory="${_DOTFILES_HELP_SOURCE%/*}" prefix=.
    local -a sources=()
    case "$topic" in
        ''|-h|--help)
            cat <<'HELP'
Dotfiles: Bash 3.2+ no Linux e macOS.
  dotfiles-help functions   Funções e descrições curtas
  dotfiles-help aliases     Atalhos e comandos associados
  dotfiles-help vars        Variáveis configuradas e valores atuais
  dotfiles-help <filtro>     Busca por nome (ex.: docker, git, cpu)
  dotfiles-help all          Catálogo completo
Namespaces: docker-, git-, fr-, show-, cleanup-, tar-, network-, ssh-.
Recarregar: reload-bashrc. Editar: edit-bash_functions, edit-bash_alias.
Helpers de sistema exigem as ferramentas da plataforma correspondente.
HELP
            return 0
            ;;
        functions|aliases|vars|all) ;;
        *) filter="$topic" ;;
    esac
    case "${_DOTFILES_HELP_SOURCE##*/}" in dot.*) prefix=dot.;; esac
    for name in bash_functions bash_alias bash_profile bash_profile-Linux bash_profile-Darwin; do
        [ ! -f "$directory/$prefix$name" ] || sources+=("$directory/$prefix$name")
    done
    for name in .bash_profile.local .bash_alias.local .bash_alias_work; do
        [ ! -f "$HOME/$name" ] || sources+=("$HOME/$name")
    done

    # Read comments as data. No documented code is sourced or evaluated.
    while IFS=$'\t' read -r kind name description syntax; do
        if [ "$exact" -eq 1 ]; then
            [ "$name" = "$filter" ] || continue
        else
            case "$name" in *"$filter"*) ;; *) continue;; esac
        fi
        case "$topic:$kind" in functions:var|vars:function|aliases:*) continue;; esac
        if [ "$kind" = function ]; then
            printf '%-38s %s\n' "$name" "$description"
        else
            value=${!name}
            printf '%-24s %s\n  %s\n' "$name" "${value:-(não definida)}" "$description"
        fi
        if [ "$kind" = function ] && [ -n "$syntax" ] &&
           { [ "$topic" = all ] || [ -n "$filter" ]; }; then
            printf '  Uso: %s\n' "$syntax"
        fi
    done < <(awk '
        function emit() {
            if (kind == "var" && name !~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) name = ""
            if (name != "" && help != "") print kind "\t" name "\t" help "\t" syntax
            kind = name = help = syntax = ""
        }
        FNR == 1 { emit() }
        /^[[:space:]]*# @var / {
            emit(); kind = "var"; name = $0
            sub(/^[[:space:]]*# @var /, "", name); next
        }
        /^[[:space:]]*# @help / {
            help = $0; sub(/^[[:space:]]*# @help /, "", help); next
        }
        /^[[:space:]]*# @syntax / {
            syntax = $0; sub(/^[[:space:]]*# @syntax /, "", syntax); next
        }
        /^(function[[:space:]]+)?[a-zA-Z0-9_.-]+\(\)[[:space:]]*\{/ {
            kind = "function"; name = $0
            sub(/^function[[:space:]]+/, "", name); sub(/\(.*/, "", name)
            emit(); next
        }
        /^[[:space:]]*#/ { next }
        { emit() }
        END { emit() }
    ' "${sources[@]}")

    if [ "$exact" -eq 0 ] &&
       { [ "$topic" = aliases ] || [ "$topic" = all ] || [ -n "$filter" ]; }; then
        while IFS= read -r definition; do
            name=${definition#alias }
            name=${name%%=*}
            case "$name" in *"$filter"*) printf '%s\n' "$definition";; esac
        done < <(alias -p)
    fi
}

# @help Expurga configurações de pacotes removidos (Debian/Ubuntu).
# @syntax dpkg-purge-all
dpkg-purge-all() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" dpkg-query sudo dpkg || return
    local packages package status
    packages=$(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n') || return
    while read -r status package; do
        [ "$status" = rc ] || continue
        sudo dpkg --purge "$package" || return
    done <<< "$packages"
}

# @help Converte vídeos para H.265 com prefixo reduced-.
# @syntax ffmpeg-reduce <vídeo> [...]
ffmpeg-reduce() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" ffmpeg || return
    local movie output
    for movie in "$@"; do
        output="${movie%/*}"
        [ "$output" != "$movie" ] || output=.
        ffmpeg -i "$movie" -vcodec libx265 -crf 20 "$output/reduced-${movie##*/}" || return
    done
}

# @help Busca executáveis no PATH por trecho do nome.
# @syntax find-bin <trecho-do-nome>
find-bin() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    local directory file
    local -a directories
    IFS=: read -r -a directories <<< "$PATH"
    for directory in "${directories[@]}"; do
        directory="${directory:-.}"
        for file in "$directory"/*; do
            [ -f "$file" ] && [ -x "$file" ] || continue
            case "${file##*/}" in *"$1"*) printf '%s\n' "$file";; esac
        done
    done | sort -u
}

# @help Atualiza o tipo de ATTRIBUTE nos arquivos de share/.
# @syntax fr-attr-update-type <atributo> <tipo-atual> <tipo-novo>
fr-attr-update-type() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 3 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    local attr="$1" old="$2" new="$3" file temporary
    case "$attr:$old:$new" in *[!a-zA-Z0-9_:.-]*)
        echo 'Use attribute and type names only.' >&2; return 2;;
    esac
    while IFS= read -r -d '' file; do
        grep -Fq -- "$attr" "$file" || continue
        temporary=$(mktemp "${file}.XXXXXX") || return
        if awk -v attr="$attr" -v old="$old" -v new="$new" '
            $1 == "ATTRIBUTE" && $2 == attr && $4 == old { $4 = new }
            { print }' "$file" > "$temporary"; then
            cat "$temporary" > "$file" || { command rm -f "$temporary"; return 1; }
        else
            command rm -f "$temporary"
            return 1
        fi
        command rm -f "$temporary"
    done < <(find share -type f -print0)
}

# @help Lista dicionários FreeRADIUS sem inclusão ou referência.
# @syntax fr-dictionary-check [diretório-fonte]
function fr-dictionary-check() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local _src="${1:-../src}" _d

    echo "# Checking missing 'dictionary.*' in ./dictionary"

    for _d in dictionary.*; do
        [ ! -f "$_d" ] && continue

        # Is it ready included?
        # I know,log(n). But, don't care about performance.
        grep -Fqx -- "\$INCLUDE ${_d}" dictionary dictionary.* && continue

        # Check if exist some source-code referencing/loading the dictionary
        # yep, its is simple. fine for now.
        if [ -d "$_src" ]; then
            grep -Fqr -- "\"${_d}" "${_src}" 2>&- && continue
        fi

        echo "\$INCLUDE $_d"
    done | grep -v -E "\.(dhcp|vqp|illegal)" | sort -n
}

# @help Extrai hexadecimal de logs recebidos pela entrada padrão.
# @syntax fr-fromlog2hex
fr-fromlog2hex() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local log
    log=$(sed 's/^.*: //g' | tr -d '\n ') || return
    fr-hex2code "$log"
}

# @help Gera representações clear/MD5 e Base64 de uma senha.
# @syntax fr-gen-password <senha>
fr-gen-password() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" openssl base64 || return
    local digest clear64 md564
    digest=$(printf '%s' "$1" | openssl dgst -md5) || return
    digest="${digest##* }"
    clear64=$(printf '{clear}%s' "$1" | base64 | tr -d '\n')
    md564=$(printf '{md5}%s' "$digest" | base64 | tr -d '\n')
    printf '## Raw\n{clear}%s\n{md5}%s\n\n# Base64\n%s\n%s\n' \
        "$1" "$digest" "$clear64" "$md564"
}

# @help Formata bytes; rev inverte bytes; usa clipboard se disponível.
# @syntax fr-hex2code <hexadecimal|arquivo> [rev]
fr-hex2code() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local hex="$1" output total
    if [ -f "$hex" ]; then
        _dotfiles-require "${FUNCNAME[0]}" xxd || return
        hex=$(xxd -p "$hex" | tr -d '\n') || return
    fi
    hex=$(printf '%s' "$hex" | tr -d '[:space:]')
    case "$hex" in ''|*[!0-9a-fA-F]*) echo 'Invalid hexadecimal input.' >&2; return 2;; esac
    [ "$((${#hex} % 2))" -eq 0 ] || { echo 'Incomplete byte.' >&2; return 2; }
    if [ "${2:-}" = rev ]; then
        hex=$(printf '%s\n' "$hex" | fold -w2 | awk '{a=$0 a} END {print a}')
    fi
    total=$((${#hex} / 2))
    output=$(printf '%s\n' "$hex" | fold -w2 | tr '\n' ' ')
    printf '# tot=%s bytes\ndecode-xxx %s\nmatch Attr-125 = 0x%s\n' "$total" "$output" "$hex"
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "$output" | pbcopy
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$output" | xclip -selection clipboard
    fi
}

# @help Anexa GDB a um PID.
# @syntax gdb-attach-by-pid <pid> [argumentos]
gdb-attach-by-pid() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -gt 0 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" gdb || return
    local pid="$1"
    shift
    case "$pid" in ''|*[!0-9]*) echo 'Invalid PID.' >&2; return 2;; esac
    gdb -p "$pid" "$@"
}

# @help Recria uma branch local a partir de master.
# @syntax git-branch-reset <branch>
git-branch-reset() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" git || return
    [ "$1" != master ] || { echo 'Cannot reset master to itself.' >&2; return 2; }
    git checkout master && git branch -D -- "$1" && git checkout -b "$1"
}

# @help Exclui branches locais e suas correspondentes em origin.
# @syntax git-cleanup-branch <branch> [...]
git-cleanup-branch() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -gt 0 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local branch
    git branch -D -- "$@" || return
    for branch in "$@"; do
        git push origin --delete "$branch" || return
    done
    git fetch --all --prune
}

# @help Exibe comandos de fixup/rebase/push; run executa.
# @syntax git-commit-as-fixup [run] [profundidade]
git-commit-as-fixup() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local run=0 depth branch previous file commit
    if [ "${1:-}" = run ]; then run=1; shift; fi
    depth="${1:-10}"
    case "$depth" in ''|*[!0-9]*) echo 'Depth must be a positive integer.' >&2; return 2;; esac
    [ "$depth" -gt 0 ] || return 2
    branch=$(git symbolic-ref --short HEAD) || return
    previous=$(git rev-parse --abbrev-ref '@{-1}') || return
    while IFS= read -r -d '' file; do
        commit=$(git log --format=%H -1 -- "$file") || return
        [ -n "$commit" ] || continue
        if [ "$run" -eq 1 ]; then
            git commit --fixup "$commit" -- "$file" || return
        else
            printf 'git commit --fixup %q -- %q\n' "$commit" "$file"
        fi
    done < <(git diff --name-only -z)
    if [ "$run" -eq 1 ]; then
        GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "HEAD~$depth" &&
            git pull --rebase upstream "$previous" &&
            git push --force-with-lease origin "$branch"
    else
        printf 'GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash %q\n' "HEAD~$depth"
        printf 'git pull --rebase upstream %q\n' "$previous"
        printf 'git push --force-with-lease origin %q\n' "$branch"
    fi
}

# @help Exibe comandos de commit para arquivos modificados.
# @syntax git-commit-as-update
git-commit-as-update() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local file
    echo "# Bash commands; use '| bash' to execute"
    while IFS= read -r -d '' file; do
        printf 'git commit -m %q -- %q\n' "Update $file" "$file"
    done < <(git diff --name-only -z)
}

# @help Exibe comandos para trocar URLs GitHub HTTPS por SSH.
# @syntax git-convert-remote2ssh
git-convert-remote2ssh() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local remote url
    while IFS= read -r remote; do
        url=$(git remote get-url "$remote") || return
        case "$url" in
            https://github.com/*)
                printf 'git remote set-url %q %q\n' \
                    "$remote" "git@github.com:${url#https://github.com/}"
                ;;
        esac
    done < <(git remote)
}

# @help Exibe fixups por arquivo modificado.
# @syntax git-fixup-by-files-last-commit
git-fixup-by-files-last-commit() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local file commit
    while IFS= read -r -d '' file; do
        commit=$(git log --format=%H -1 -- "$file") || return
        [ -n "$commit" ] || continue
        printf 'git commit --fixup %q -- %q\n' "$commit" "$file"
    done < <(git diff --name-only -z)
}

# @help Cria fixup no último commit e executa autosquash.
# @syntax git-fixup-with-last-commit [arquivo ...]
git-fixup-with-last-commit() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local commit base
    commit=$(git rev-parse HEAD) || return
    [ "$#" -gt 0 ] || set -- .
    base=$(git rev-parse --verify "${commit}^" 2>/dev/null) || base=--root
    git commit --fixup "$commit" -- "$@" || return
    GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "$base"
}

# @help Abre arquivos modificados no Sublime Text.
# @syntax git-open-changed-with-subl
git-open-changed-with-subl() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git subl || return
    local file
    local -a files=()
    while IFS= read -r -d '' file; do files+=("$file"); done < <(git diff --name-only -z)
    [ "${#files[@]}" -gt 0 ] || return 0
    subl -- "${files[@]}"
}

# @help Mostra branch atual ou hash de HEAD destacado.
# @syntax git-parse-branch
git-parse-branch() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

# @help Envia todas as branches locais a origin.
# @syntax git-push-all-origin-branches
git-push-all-origin-branches() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local branches branch
    branches=$(git for-each-ref --format='%(refname:short)' refs/heads/) || return
    while IFS= read -r branch; do
        [ -n "$branch" ] || continue
        git push origin "refs/heads/$branch:refs/heads/$branch" || return
    done <<< "$branches"
}

# @help Executa rebase autosquash; profundidade padrão: 30.
# @syntax git-rebase-fixup-autosquash [profundidade]
git-rebase-fixup-autosquash() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local depth="${1:-30}"
    case "$depth" in ''|*[!0-9]*) echo 'Depth must be a positive integer.' >&2; return 2;; esac
    [ "$depth" -gt 0 ] || return 2
    GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash "HEAD~$depth"
}

# @help Lista commits inacessíveis e cria referências lost-found.
# @syntax git-show-lost-found
git-show-lost-found() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" git || return
    local _kind type hash
    git fsck --full --no-reflogs --unreachable --lost-found |
        while read -r _kind type hash; do
            [ "$type" = commit ] || continue
            git log -n 1 --pretty=oneline "$hash"
        done
}

# @help Retorna 0 quando o comando existe (função, alias ou executável).
# @syntax have <comando>
have() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    command -v "${1:?comando}" >/dev/null 2>&1
}

# @help Organiza palavras em grupos de oito e conta o total.
# @syntax hex-count <byte ...>
hex-count() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local total
    printf '%s\n' "$*" | tr ' ' '\n' | paste - - - - - - - -
    total=$(printf '%s\n' "$*" | awk '{n += NF} END {print n+0}')
    printf '\n# Total: %d (%#x)\n' "$total" "$total"
}

# @help Testa TCP nos dois sentidos; destino padrão: IPERF3_HOST ou localhost.
# @syntax iperf3-test [destino ...]
iperf3-test() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" iperf3 || return
    local dst
    [ "$#" -gt 0 ] || set -- "${IPERF3_HOST:-localhost}"
    for dst in "$@"; do
        printf '# Connecting to %s: client to server\n' "$dst"
        iperf3 -c "$dst" || return
        echo '# TCP server to client'
        iperf3 -R -c "$dst" || return
    done
}

# @help Executa iperf3 contra o servidor público configurado.
# @syntax iperf3-test-publicips [opções-iperf3]
iperf3-test-publicips() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" iperf3 || return
    iperf3 -c iperf.par2.as49434.net -p 9201 "$@"
}

# @help Converte IPv6 em hexadecimal usando sipcalc.
# @syntax ipv62hex <IPv6>
ipv62hex() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" sipcalc || return
    echo "# ~> Converting $1 to hexa"

    sipcalc "$1" | sed '/Compressed addres/!d; s/.*- //g; s/://g; s/^/0x/g'
}

# @help Sincroniza disco e limpa caches do kernel (Linux).
# @syntax linux-clear-caches
linux-clear-caches() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" sudo sysctl || return
    [ "$(uname -s)" = Linux ] || { echo 'Linux only.' >&2; return 1; }
    sync
    sudo sysctl -w vm.drop_caches=3
}

# @help Abre manuais com cores no pager less.
# @syntax man [seção] <página>
man() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" man || return
    # begin blinking
    # begin bold
    # end mode
    # end standout-mode
    # begin standout-mode - info box
    # end underline
    # begin underline

    env LESS_TERMCAP_mb="$(printf "\e[1m")" \
        LESS_TERMCAP_md="$(printf "\e[1;32m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;37m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;33m")" \
        man "$@"
}

# @help Conecta a MYSQL_HOST com senha interativa; usuário MYSQL_USER ou root.
# @syntax mysql-connect [opções-mysql]
mysql-connect() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" mysql || return
    local host="${MYSQL_HOST:-}"
    [ -n "$host" ] || {
        echo 'mysql-connect: configure MYSQL_HOST em ~/.bash_profile.local' >&2
        return 2
    }
    mysql -u "${MYSQL_USER:-root}" -p -h "$host" "$@"
}

# @help Consulta o IP público via OpenDNS/dig.
# @syntax network-public-ip [opções-dig]
network-public-ip() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" dig || return
    printf '# dig +short myip.opendns.com @resolver1.opendns.com %s\n' "$*"
    dig +short myip.opendns.com @resolver1.opendns.com "$@"
}

# @help Mostra quantidade de CPUs lógicas.
# @syntax show-cpu-cores
show-cpu-cores() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    getconf _NPROCESSORS_ONLN
}

# @help Mostra temperatura com osx-cpu-temp ou sensors.
# @syntax show-cpu-temp
show-cpu-temp() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    if command -v osx-cpu-temp >/dev/null 2>&1; then
        osx-cpu-temp -Ccgf
    elif command -v sensors >/dev/null 2>&1; then
        sensors
    else
        echo 'show-cpu-temp: instale osx-cpu-temp (macOS) ou lm-sensors (Linux)' >&2
        return 127
    fi
}

# @help Escreve e lê 8096 MiB em arquivo temporário; aceita diretório.
# @syntax show-disk-speed [diretório]
show-disk-speed() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local directory="${1:-$PWD}" temporary status=0
    temporary=$(mktemp "$directory/disk-speed.XXXXXX") || return
    echo '# Writing and reading 8096 MiB'
    dd if=/dev/zero of="$temporary" bs=1048576 count=8096 || status=$?
    sync
    if [ "$status" -eq 0 ]; then
        dd if="$temporary" of=/dev/null bs=1048576 || status=$?
    fi
    command rm -f -- "$temporary"
    return "$status"
}

# @help Exibe certificados X.509 com OpenSSL.
# @syntax show-openssl-cert-infos <certificado> [...]
show-openssl-cert-infos() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" openssl || return
    local file
    for file in "$@"; do
        openssl x509 -in "$file" -noout -text || return
    done
}

# @help Lista RSS em MiB, PID, usuário e comando.
# @syntax show-process-memory-usage
show-process-memory-usage() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    ps -axo rss=,pid=,user=,command= | sort -nr -k1,1 | awk '
        { printf "%13.2f MiB %s %s", $1 / 1024, $2, $3
          for (i = 4; i <= NF; i++) printf " %s", $i
          print "" }'
}

# @help Gera quatro bytes aleatórios no formato IPv4.
# @syntax show-random-ip
show-random-ip() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    dd if=/dev/urandom bs=4 count=1 2>/dev/null |
        od -An -tu1 | awk '{printf "%d.%d.%d.%d\n", $1, $2, $3, $4}'
}

# @help Mostra uso de disco das entradas de HOME.
# @syntax show-size-of-my-home
show-size-of-my-home() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file
    for file in "$HOME"/* "$HOME"/.[!.]* "$HOME"/..?*; do
        [ -e "$file" ] || [ -L "$file" ] || continue
        du -sh "$file"
    done
}

# @help Mostra Wi-Fi via system_profiler (macOS) ou nmcli/watch (Linux).
# @syntax show-wifi
show-wifi() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    if [ "$(uname -s)" = Darwin ]; then
        _dotfiles-require "${FUNCNAME[0]}" system_profiler || return
        system_profiler SPAirPortDataType
    else
        _dotfiles-require "${FUNCNAME[0]}" watch nmcli || return
        watch -n2 'nmcli -f "CHAN,BARS,SIGNAL,SSID" d wifi list'
    fi
}

# @help Lista os hosts de ~/.ssh/config (e Include) e de MYSERVERS, sem curingas.
# @syntax ssh-list
ssh-list() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file word line
    local -a files=("$HOME/.ssh/config")
    # Segue as diretivas Include de primeiro nível, expandindo globs.
    while IFS= read -r line; do
        for word in ${line#*[Ii]nclude}; do
            case "$word" in /*) ;; "~"/*) word="$HOME/${word#"~"/}";; *) word="$HOME/.ssh/$word";; esac
            for file in $word; do [ -f "$file" ] && files+=("$file"); done
        done
    done < <(grep -i '^[[:space:]]*include[[:space:]]' "${files[0]}" 2>/dev/null)
    {
        for file in "${files[@]}"; do
            [ -f "$file" ] || continue
            awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' "$file"
        done
        printf '%s\n' ${MYSERVERS:-}
    } | grep -v '[*?!]' | sort -u
}

# Completa o host de ssh/scp/sftp/ssh-copy-id com ssh-list.
_ssh-complete-hosts() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    case "$cur" in -*) return 0;; esac
    local IFS=$'\n'
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$(ssh-list)" -- "$cur"))
}
complete -o default -F _ssh-complete-hosts ssh scp sftp ssh-copy-id

# @help Transmite captura remota por SSH para Wireshark.
# @syntax ssh-tcpdump-to-wireshark <host> <interface> <filtro>
ssh-tcpdump-to-wireshark() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 3 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" ssh wireshark || return
    local iface filter
    # OpenSSH passes a command string to the remote POSIX shell.
    iface=${2//\'/\'\\\'\'}
    filter=${3//\'/\'\\\'\'}
    (set -o pipefail; ssh -- "$1" "tcpdump -U -i '$iface' -w - '$filter'" | wireshark -k -i -)
}

# @help Extrai cada .tar em seu próprio diretório.
# @syntax tar-extract <arquivo.tar> [...]
tar-extract() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local archive directory
    for archive in "$@"; do
        directory="${archive##*/}"
        directory="${directory%.tar}"
        directory="${directory%.tgz}"
        mkdir -p -- "$directory" || return
        tar xvf "$archive" -C "$directory" || return
    done
}

# @help Extrai cada .tar.gz/.tgz em seu próprio diretório.
# @syntax tar-extract-gzip <arquivo.tar.gz|arquivo.tgz> [...]
tar-extract-gzip() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local archive directory
    for archive in "$@"; do
        directory="${archive##*/}"
        directory="${directory%.tar.gz}"
        directory="${directory%.tgz}"
        mkdir -p -- "$directory" || return
        tar xzvf "$archive" -C "$directory" || return
    done
}

# @help Captura HTTP; aceita interface e opções extras de tcpdump.
# @syntax tcpdump-http [interface] [opções-tcpdump]
tcpdump-http() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" sudo tcpdump || return
    local iface="${1:-any}"
    [ "$#" -eq 0 ] || shift
    if [ "$iface" = any ] && [ "$(uname -s)" = Darwin ]; then
        iface=pktap,all
    fi
    sudo tcpdump -nve -i "$iface" -A -s 0 \
        'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' "$@"
}

# @help Soma números decimais no começo das linhas.
# @syntax text-sum-decimals [arquivo ...]
text-sum-decimals() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    grep -Eo '^[0-9]+\.[0-9]{1,9}' "$@" |
        awk '{ n += $1 } END { printf("Total: %f\n", n); }'
}

# @help Exibe comando exiftool com a data/hora atual.
# @syntax update-photos-date-to <arquivo> [...]
update-photos-date-to() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local date
    date=$(date '+%Y-%m-%d %H:%M:%S') || return
    echo "# Bash command; use '| bash' to execute"
    printf 'exiftool %q -overwrite_original' "-AllDates=$date"
    printf ' %q' "$@"
    printf '\n'
}

# @help Grava DNS Google em /etc/resolv.conf (Linux).
# @syntax update-resolvconf2google8888
function update-resolvconf2google8888() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    _dotfiles-require "${FUNCNAME[0]}" sudo tee ping || return
    [ "$(uname -s)" = Linux ] || { echo 'Linux only.' >&2; return 1; }
    sudo tee /etc/resolv.conf <<EOF
# Created at $(date) by update-resolvconf2google8888
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    local status=$?
    [ "$status" -eq 0 ] || return "$status"

    echo "------------- /etc/resolv.conf"
    cat /etc/resolv.conf

    echo "------------- testing"
    ping -c2 www.google.com.br
}

# @help Exibe comandos VirtualBox para redimensionar um VMDK.
# @syntax vbox-resize-vmdk-commands [nome-sem-extensão] [tamanho-MiB]
vbox-resize-vmdk-commands() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local vm="${1:-foo}" size="${2:-30720}"
    case "$size" in ''|*[!0-9]*) echo 'Size must be an integer in MiB.' >&2; return 2;; esac
    printf 'VBoxManage clonehd %q %q --format VDI --variant Standard\n' "$vm.vmdk" "$vm.vdi"
    printf 'mv %q %q\n' "$vm.vmdk" "$vm.vmdk.orig"
    printf 'VBoxManage modifyhd %q --resize %q\n' "$vm.vdi" "$size"
    printf 'VBoxManage clonehd %q %q --format VMDK --variant Standard\n' "$vm.vdi" "$vm.vmdk"
}

# @help Converte arquivo em HTML usando Vim TOhtml.
# @syntax vim-to-html <arquivo>
vim-to-html() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    [ "$#" -eq 1 ] || {
        dotfiles-help --exact "${FUNCNAME[0]}" >&2
        return 2
    }
    _dotfiles-require "${FUNCNAME[0]}" vim || return
    vim -c 'let g:html_no_progress = 1' -c 'set bg=dark' -c TOhtml -c 'w!' -c 'qa!' -- "$1"
}

# @help Exibe comandos dwebp para os arquivos .webp do diretório.
# @syntax webp2png
webp2png() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local file
    for file in *.webp; do
        [ -f "$file" ] || continue
        printf 'dwebp -o %q %q\n' "${file%.webp}.png" "$file"
    done
}

# Compatibility names.
alias docker_banner='docker-banner'
alias fr.dictinary-check='fr-dictionary-check'
alias git_parse_branch='git-parse-branch'
alias open-git-changed-with-subl='git-open-changed-with-subl'
alias noback='cleanup-backup-files'
alias ssh-cleanup-sessions='cleanup-ssh-sessions'
alias git-enable-debug='export GIT_CURL_VERBOSE=1 GIT_TRACE=1'
alias git-disable-debug='unset GIT_CURL_VERBOSE GIT_TRACE'

alias my-clean-buffersmemory='linux-clear-caches'
alias my-diff-by-2dates='date-months-between'
alias my-extract-tar='tar-extract'
alias my-extract-tgz='tar-extract-gzip'
alias my-ffmpeg-reduce='ffmpeg-reduce'
alias my-hexcount='hex-count'
alias my-ip='network-public-ip'
alias my-nobacks='cleanup-backup-files'
alias my-ssh-tcpdump2wireshark='ssh-tcpdump-to-wireshark'
alias my-sum-dotplus8='text-sum-decimals'
alias my-vm-increase-vmdk='vbox-resize-vmdk-commands'
alias qnap-mysql-connect='mysql-connect'
