#!/bin/bash
# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Qui 12 Dez 2013 18:55:40 BRST
##

# Enviroments
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

unset PS1
#export PS1="\[\e[44;33;1m\][\e["$high"m\u\e[44;33;1m@\e[44;32m\h \W]\$\[\e[m\] "
export PS1="\[\e[44;33;1m\][\e["$high"m\u\e[44;33;1m@\e[44;32m\h \W]\e[47;30m\\$\[\e[m\] "
export PS1="[\u@\h \W]\\$ "

#export LC_CTYPE="en_US.iso-8859-1"
export EMAIL_ADDRESS="jorge@jorgepereira.com.br"
export CHANGE_LOG_EMAIL_ADDRESS="${EMAIL_ADDRESS}"
export CHANGE_LOG_NAME="Jorge Pereira"
export ESCDELAY=0
export EDITOR="vim"
export SVN_EDITOR="$EDITOR"
export CVS_EDITOR="$EDITOR"
export JAVA_HOME="/usr/lib/jvm/java-6-sun/"
export JAVA_BIN="$JAVA_HOME/bin/"
export PATH=""
export PATH="$HOME/bin:$PATH:$JAVA_BIN:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/cxoffice/bin:/usr/games:/opt/glade/bin:/home/usr/bin:/home/usr/sbin"
#export MALLOC_CHECK_=2
export HISTCONTROL="ignoredups"
export VINO_SESSION_DEBUG=1
export ZZPATH="$HOME/bin/funcoeszz"
export PROMPT_COMMAND='if [[ $? -ne 0 ]]; then echo  -ne "\033[1;31m:(\033[0m\n";fi'

#export CPPFLAGS="-g3 -ggdb"
#ulimit -c1
ulimit -c unlimited

# Criando o $HOME/bin caso nao exista
[ -L $HOME/bin -o -d $HOME/bin ] || mkdir -p $HOME/bin

# Limitando quantidades de processos
#if [ "$USER" == "root" ]; then
#  ulimit -S -u 512
#else
#  ulimit -S -u 256
#fi 

# Carregando alias personalizadas
if [ -f $HOME/.bash_alias ];then
  source $HOME/.bash_alias
fi

# Carregando funcoes personalizadas
if [ "$TERM" != "dumb" -a -f $HOME/.bash_functions ];then
	source $HOME/.bash_functions
fi

# Carregando o funcoeszz
if [ -f $HOME/bin/funcoeszz ];then
  source $HOME/bin/funcoeszz
fi

# allow xhost
#if [ $UID != 0 ];then
#	xhost + 1> /dev/null 2>&1
#fi

# fortune!
if [ -x /usr/games/fortune ];then
  /usr/games/fortune /usr/share/games/fortunes/brasil
fi

