# Por Jorge Pereira <jpereiran@gmail.com>
# Last Change: Wed 29 May 2019 12:52:31 PM EDT
##
echo "#.bash_profile Carregando"

export OS="$(uname -s)"
export PATH="/opt/radius/bin:$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/snap/bin"
export PATH="~/Devel/Android/Sdk/platform-tools/:$PATH"
export PATH="~/bin/netExtenderClient:$PATH"

#export PATH_OLD="$PATH"

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_COLLATE="C"
#export MALLOC_CHECK_=2
export HISTCONTROL="ignoredups"
export ESCDELAY=0
export EDITOR="vim"

export EMAIL_ADDRESS="jpereiran@gmail.com"
export CHANGE_LOG_EMAIL_ADDRESS="${EMAIL_ADDRESS}"
export CHANGE_LOG_NAME="Jorge Pereira"

export SVN_EDITOR="$EDITOR"
export CVS_EDITOR="$EDITOR"
export ZZPATH="$HOME/bin/funcoeszz"
export ANDROID_TOOLCHAIN="/opt/android-ndk/toolchain/toolchains"

#export GIT_CURL_VERBOSE=1
#export GIT_TRACE=1

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
    #export PROMPT_COMMAND='if [[ $? -ne 0 ]]; then echo  -ne "\033[1;31m:(\033[0m\n";fi'
  ;;

  *)
  ;;
esac

# Criando o $HOME/bin caso nao exista
[ -L $HOME/bin -o -d $HOME/bin ] || mkdir -p $HOME/bin

# Carregando alias personalizadas
rc_so="~/.bash_profile-$SO"
dots=(.bash_alias .bash_functions bin/funcoeszz $rc_so)

for d in ${dots[*]}; do
    dot="$HOME/$d"
    #echo "Carregando $dot"
    if [ "$TERM" != "dumb" -a -f "$dot" ];then
        echo "Carregando $dot"
        source $dot
    fi
done

if [ -n "$DISPLAY" ]; then
  if [ -f ~/.Xmodmap ]; then
    #echo "Loading ~/.Xmodmap"
    xmodmap ~/.Xmodmap
  fi
fi


# fortune!
if [ -x /usr/games/fortune ];then
  /usr/games/fortune /usr/share/games/fortunes/brasil
fi

# always core files
ulimit -c unlimited

