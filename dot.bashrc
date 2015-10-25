# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Sex Dez 13 14:33:34 BRST 2013
# ###

if [ "$TERM" != "dumb" ]; then

	export PATH="/opt/radius/bin/:/bin:/sbin:/usr/bin:/usr/sbin:$PATH"

	# Source global definitions
	echo "#.bashrc: Carregando /etc/bashrc"
	[ -f /etc/bashrc ] && . /etc/bashrc

	echo "#.bashrc: Carregando .bash_profile"
	[ -f ~/.bash_profile ] && source ~/.bash_profile

	echo "feito"
fi
