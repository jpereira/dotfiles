# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Mon Jun 24 12:37:13 2019
##

#
# Disable the print messages
#
NODEBUG=1

decho() {
  [ -z "$NODEBUG" ] && echo "# ~> $@"
}

#
# Main
#
decho "$HOME/.bash_profile"

#
# Global vars
#
export OS="$(uname -s)"
export PATH="$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_COLLATE="C"
#export MALLOC_CHECK_=2
export HISTCONTROL="ignoredups"
export ESCDELAY=0
export EDITOR="vim"
export DISPLAY=${DISPLAY:-:0.0}
export GPG_TTY=$(tty)

#
# Settings by $OS
#
[ -f "$HOME/.bash_profile-$OS" ] && source "$HOME/.bash_profile-$OS"

#
# Different colors for root & nonroot 
#
if [ $UID -eq 0 ];then
    high="40;31"
else
    high="40;34"
fi

#
# Git
#
export EMAIL_ADDRESS="jpereiran@gmail.com"
export CHANGE_LOG_EMAIL_ADDRESS="${EMAIL_ADDRESS}"
export CHANGE_LOG_NAME="Jorge Pereira"
export SVN_EDITOR="$EDITOR"
export CVS_EDITOR="$EDITOR"

parse_git_branch(){
  local he="$(git branch 2>&- | sed '/^\*/!d; s/.* //')"

  if [ ! -z $he ]; then
    echo -ne "\e[40;36;1m($he)\e[0m"
  fi
}

#
# Terminal
#
export PS1="[\u@\h \W]\\$ "

case "$TERM" in
  xterm*|rxvt*)
    #export PROMPT_COMMAND='if [[ $? -ne 0 ]]; then echo  -ne "\033[1;31m:(\033[0m\n";fi'
  ;;

  *)
  ;;
esac

#
# Home bin
#
[ -L $HOME/bin -o -d $HOME/bin ] || mkdir -p $HOME/bin

#
# Load personal bash_profiles.
#
# e.g: for business & customers & OS
#
dots=(.bash_functions .bash_alias bin/funcoeszz)

for d in ${dots[*]}; do
    dot="$HOME/$d"

    if [ "$TERM" != "dumb" -a -f "$dot" ];then
        decho "$dot"
        source $dot
    fi
done

#
# Display/X11
#
if [ -n "$DISPLAY" ]; then
  if which xmodmap 1> /dev/null 2>&1; then
    decho "~/.Xmodmap"
    xmodmap ~/.Xmodmap
  fi
fi

#
# fortune!
#
if [ -x /usr/games/fortune ];then
  /usr/games/fortune /usr/share/games/fortunes/brasil
elif which fortune 1> /dev/null 2>&1; then
  fortune
fi

# always core files
ulimit -c unlimited
