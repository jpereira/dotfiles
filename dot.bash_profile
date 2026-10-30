# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Wed Oct  7 14:15:00 2026
##

#
#	Disable the print messages
#
case $- in *i*) ;; *) return ;; esac

# @var NODEBUG
# @help Vazia habilita decho; preenchida silencia diagnóstico.
NODEBUG=${NODEBUG-1}

# @help Exibe diagnóstico quando NODEBUG está vazio.
# @syntax decho [mensagem ...]
decho() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
  if [ -z "$NODEBUG" ]; then printf '# ~> %s\n' "$*"; fi
}

#
#	Main
#
decho "$HOME/.bash_profile"

#
#	Global vars
#
# @var OS
# @help Sistema detectado por uname: Linux ou Darwin.
OS=$(uname -s)
export OS
# Add existing directories once and preserve the caller's PATH.
# @var PATH
# @help Diretórios usados para procurar executáveis.

# @help Adiciona diretórios existentes ao PATH sem duplicar entradas.
# @syntax path-prepend <diretório> [...]
path-prepend() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local directory
    for directory in "$@"; do
        [ -d "$directory" ] || continue
        case ":$PATH:" in *":$directory:"*) ;; *) PATH="$directory:$PATH";; esac
    done
    export PATH
}
path-prepend /usr/local/sbin /usr/local/bin "$HOME/.local/bin" "$HOME/bin" \
    "$HOME/bin/$OS" "$HOME/.docker/bin"
if [ "$OS" = Darwin ]; then
    path-prepend /opt/homebrew/bin
fi
# Respect installed/user-selected locales (LC_ALL would override LC_COLLATE).
# @var LANG
# @help Locale principal; respeita o ambiente recebido.
export LANG="${LANG:-C}"
# @var LC_COLLATE
# @help Ordenação de texto; padrão C.
export LC_COLLATE="C"
#export MALLOC_CHECK_=2

# Data/hora associada aos comandos do historico
# @var HISTTIMEFORMAT
# @help Formato da data/hora no comando history.
export HISTTIMEFORMAT='[%Y-%m-%d %H:%M:%S] '

# Tamanho do historico
# @var HISTSIZE
# @help Quantidade de comandos mantidos na memória.
export HISTSIZE=100000
# @var HISTFILESIZE
# @help Limite de linhas do arquivo de histórico.
export HISTFILESIZE=200000

# Ignorar comandos duplicados consecutivos
# @var HISTCONTROL
# @help ignoredups ignora duplicatas consecutivas.
HISTCONTROL=ignoredups

# Adicionar ao historico, sem sobrescrever outras sessoes
shopt -s histappend

# @var ESCDELAY
# @help Espera por sequências Escape em programas ncurses.
export ESCDELAY=0
# @var EDITOR
# @help Editor padrão; pode conter argumentos simples separados por espaços.
export EDITOR="${EDITOR:-vim}"
if [ -t 0 ]; then
    # @var GPG_TTY
    # @help Terminal associado ao GnuPG quando há TTY.
    GPG_TTY=$(tty)
    export GPG_TTY
fi
if command -v llvm-symbolizer >/dev/null 2>&1; then
    # @var ASAN_SYMBOLIZER_PATH
    # @help Caminho de llvm-symbolizer quando disponível.
    ASAN_SYMBOLIZER_PATH=$(command -v llvm-symbolizer)
    export ASAN_SYMBOLIZER_PATH
fi
# @var NPROC
# @help CPUs lógicas detectadas na inicialização.
NPROC=$(getconf _NPROCESSORS_ONLN 2>/dev/null) || NPROC=1
# @var NCPU
# @help CPUs lógicas; usada por pmake.
export NPROC NCPU="$NPROC"

#
#	FreeRADIUS
#
#export FR_LIBRARY_PATH=./build/lib/local/.libs/

#
#	Ansible settings
#

#
# Git
#
# @var SVN_EDITOR
# @help Editor de mensagens do Subversion.
export SVN_EDITOR="$EDITOR"
# @var CVS_EDITOR
# @help Editor de mensagens do CVS.
export CVS_EDITOR="$EDITOR"

# @help Formata o nome da branch com cores para o prompt.
# @syntax parse_git_branch
parse_git_branch() {
    case "${1:-}" in -h|--help) dotfiles-help --exact "${FUNCNAME[0]}"; return;; esac
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return 0
    printf '\033[40;36;1m(%s)\033[0m' "$branch"
}

#
# Settings by $OS
#
# shellcheck disable=SC1090
[ -f "$HOME/.bash_profile-$OS" ] && source "$HOME/.bash_profile-$OS"

#
#	Terminal
#
#export PS1="[\u@\h \W]\\$ "

# Data/hora, usuário, host e diretório; escapes delimitados para o Readline.
# @var PS1
# @help Prompt com data/hora, usuário, host e diretório.
export PS1='\[\e[1;97;40m\][\[\e[0;38;5;250;40m\]\D{%Y-%m-%d} \t\[\e[1;97;40m\]] [\[\e[0;93;40m\]\u\[\e[0;94;40m\]@\[\e[0;91;40m\]\h:\[\e[0;92;40m\]\w\[\e[1;97;40m\]]\[\e[0;96;40m\]\$ \[\e[0m\]'

if [ "${TERM:-dumb}" = dumb ]; then
    PS1='[\u@\h \w]\$ '
fi

if [ -e "/.dockerenv" ] && [ "${TERM:-dumb}" != dumb ]; then
  export PS1='\[\e[41;4;33m\]Docker\[\e[m\]~>'"$PS1"
fi

case "${TERM:-dumb}" in
  xterm*|rxvt*)
    #export PROMPT_COMMAND='if [[ $? -ne 0 ]]; then echo  -ne "\033[1;31m:(\033[0m\n";fi'
  ;;

  *)
  ;;
esac

#
#	Home bin
#
[ -d "$HOME/bin" ] || mkdir -p "$HOME/bin"

#
# Load personal bash_profiles.
#
# e.g: for business & customers & OS
#
# Third-party completions may require newer builtins (for example complete -o nosort).
if [ "${TERM:-dumb}" != dumb ] &&
   { [ "${BASH_VERSINFO[0]}" -gt 4 ] ||
     { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -ge 4 ]; }; }; then
    for completion in /opt/homebrew/etc/profile.d/bash_completion.sh \
                      /usr/local/etc/profile.d/bash_completion.sh \
                      /etc/profile.d/bash_completion.sh \
                      /etc/bash_completion; do
        if [ -f "$completion" ]; then
            # shellcheck disable=SC1090
            source "$completion"
            break
        fi
    done
    unset completion
fi

for d in "$HOME/.bash_functions" "$HOME/.bash_alias" "$HOME/bin/funcoeszz"; do
    [ -f "$d" ] || continue
    decho "$d"
    # shellcheck disable=SC1090
    source "$d"
done
unset d

#
#	Display/X11
#
if [ -n "${DISPLAY:-}" ] && [ -f "$HOME/.Xmodmap" ]; then
  if command -v xmodmap >/dev/null 2>&1; then
    decho "$HOME/.Xmodmap"
    xmodmap "$HOME/.Xmodmap"
  fi
fi

#
#	fortune!
#
#if [ -x /usr/games/fortune ];then
#  /usr/games/fortune /usr/share/games/fortunes/brasil
#elif which fortune 1> /dev/null 2>&1; then
#  fortune
#fi

#	always core files?
#ulimit -c unlimited
# sudo launchctl limit core 0 0

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

if [ -f ~/.docker/init-bash.sh ]; then
	# shellcheck disable=SC1090
	source "$HOME/.docker/init-bash.sh" || true # Added by Docker Desktop
fi


# Local files override shared preferences. The legacy work file remains optional.
for d in "$HOME/.bash_profile.local" "$HOME/.bash_alias.local" "$HOME/.bash_alias_work"; do
    [ -f "$d" ] || continue
    # shellcheck disable=SC1090
    source "$d"
done
unset d
if [ -f "$HOME/.bash_alias_work" ]; then
    alias edit-alias-work='_edit-config "$HOME/.bash_alias_work" reload'
fi
true
