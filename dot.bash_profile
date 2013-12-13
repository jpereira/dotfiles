#!/bin/bash
# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Sex 13 Dez 2013 16:39:06 BRST
##

export PATH="$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
#export LC_CTYPE="en_US.iso-8859-1"
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

#export PS1="\[\e[44;33;1m\][\e["$high"m\u\e[44;33;1m@\e[44;32m\h \W]\$\[\e[m\] "
#export PS1="\[\e[44;33;1m\][\e["$high"m\u\e[44;33;1m@\e[44;32m\h \W]\e[47;30m\\$\[\e[m\] "
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

# allow xhost
#if [ $UID != 0 ];then
#	xhost + 1> /dev/null 2>&1
#fi

# fortune!
if [ -x /usr/games/fortune ];then
  /usr/games/fortune /usr/share/games/fortunes/brasil
fi

#ulimit -c1
ulimit -c unlimited

