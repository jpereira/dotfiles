#!/bin/bash
# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Qui Dez 12 15:44:15 BRST 2013
###

OS="$(uname -s)"

if [ "$1" != "run" ]; then
    echo "Usage: $0 <run>"
    echo
    echo "ATTENTION: It will create a symbolic-link from all dot.<name> to ~/.<name> overwriting everything in $HOME/"

    exit
fi

# main
for dot in $(ls -1 | grep ^dot); do {
    nodot="${dot//dot./}"
    from="${PWD}/$dot"
    to="${HOME}/.${nodot}"

    #echo "Debug: dot=$dot nodot=$nodot from=$from to='$to'"

    if echo "$from" | grep -q "dot.config"; then
        #echo "Ignoring $from"
        continue
    fi

    ln -fs $from $to
} done
