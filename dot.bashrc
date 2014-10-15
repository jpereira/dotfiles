#!/bin/bash
# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Sex Dez 13 14:33:34 BRST 2013
# ###

if [ "x$TERM" != "xdumb" ]; then

    echo "Carregando .bashrc..."

    export PATH="/bin:/sbin:/usr/bin:/usr/sbin:$PATH"

    # Source global definitions
    [ -f /etc/bashrc ] && . /etc/bashrc
    [ -f ~/.bash_profile ] && . ~/.bash_profile
fi

