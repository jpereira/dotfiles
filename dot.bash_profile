#!/bin/bash
# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Tue Oct 21 00:40:22 2014
##

echo "Carregando .bash_profile..."

case $(uname -s) in
    Darwin)
        export LSCOLORS=ExFxCxDxBxegedabagacad
        export CLICOLOR=1
        export ARG_LS="-G"
        export PS1='\[\e[0;33m\]\h:\W \u\$\[\e[m\] '
    ;;

    *)
        export ARG_LS="--color=auto"
esac

export PATH="$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
#export LC_CTYPE="en_US.iso-8859-1"

export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"

export LC_COLLATE="C"
export EMAIL_ADDRESS="jpereiran@gmail.com"
export CHANGE_LOG_EMAIL_ADDRESS="${EMAIL_ADDRESS}"
export CHANGE_LOG_NAME="Jorge Pereira"

export HISTCONTROL="ignoredups"
export ESCDELAY=0

export EDITOR="vim"
export SVN_EDITOR="$EDITOR"
export CVS_EDITOR="$EDITOR"
#export MALLOC_CHECK_=2
export ZZPATH="$HOME/bin/funcoeszz"

# Terminal
# Alterando a cor do terminal
if [ $UID -eq 0 ];then
    high="40;31"
else
    high="40;34"
fi

parse_git_branch(){
    local he="$(git branch 2>&- | sed '/^\*/!d; s/.* //')"

	if [ ! -z $he ]; then
	    echo -ne "\e[40;36;1m($he)\e[0m"
	fi
}

export PS1="[\u@\h \W]\\$ "

case "$TERM" in
  xterm*|rxvt*)
    #export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
    export PROMPT_COMMAND='if [[ $? -ne 0 ]]; then echo  -ne "\033[1;31m:(\033[0m\n";fi'
  ;;

  *)
  ;;
esac

# Criando o $HOME/bin caso nao exista
[ -L $HOME/bin -o -d $HOME/bin ] || mkdir -p $HOME/bin

# Carregando alias personalizadas
dots=(.bash_alias .bash_functions bin/funcoeszz)

for d in ${dots[*]}; do
    dot="$HOME/$d"
    #echo "Carregando $dot"
    if [ "$TERM" != "dumb" -a -f "$dot" ];then
        source $dot
    fi
done

# fortune!
if [ -x /usr/games/fortune ];then
  /usr/games/fortune /usr/share/games/fortunes/brasil
fi

ulimit -c unlimited

