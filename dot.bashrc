#!/bin/bash
# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Sex Dez 13 14:33:34 BRST 2013
# ###

echo "Carregando .bashrc..."

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

[ -f ~/.bash_profile ] && . ~/.bash_profile

