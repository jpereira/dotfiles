# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Sex Dez 13 14:33:34 BRST 2013
# ###

alias ls="ls -G"
if [ "$TERM" != "dumb" ]; then

	export PATH="/opt/homebrew/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

	# Source global definitions
	#echo "#.bashrc: Carregando /etc/bashrc"
	[ -f /etc/bashrc ] && . /etc/bashrc

	#echo "#.bashrc: Carregando .bash_profile"
	[ -f ~/.bash_profile ] && source ~/.bash_profile
fi


source /Users/jpereira/.docker/init-bash.sh || true # Added by Docker Desktop
