# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: ter 16 abr 2019 21:00:29 -03
# Created: Mon 01 Jun 1999 01:22:10 AM BRT
##
git-remote2ssh() {
  git remote -v | awk '/\(fetch\)$/ {
    gsub("https://github.com/", "git@github.com:", $2)

    printf("git remote set-url %s %s\n", $1, $2)
  }'
}

show-wifi() {
	watch -n2 'nmcli -f "CHAN,BARS,SIGNAL,SSID" d wifi list'
}

cleanup-ssh-sessions() {
	rm -fv ~/.ssh/sessions/*
}

cleanup-snap() {

	snap list --all | awk '/disabled/{print $1, $3}' | \
	while read snapname revision; do
		sudo snap remove "$snapname" --revision="$revision"
	done
}

parse_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function update-resolvconf2google8888 (){
	echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
	cat /etc/resolv.conf
	echo "------------- testing"
	ping -c2 www.google.com.br
}

function vim-to-html() {
   local in="$1"

   if [ -z "$in" ]; then
       echo "Usage: $0 </path/caipirinha.c>"
       return
   fi

   echo "Converting $in to HTML ${in}.html" 

   vim -c "let g:html_no_progress = 1" -c "set bg=dark" -c TOhtml -c "w!" -c 'qa!' $in
}

radius-get_def() {
#    [ -n "$1" ] && d="$1" || d="src/"

    grep --color '"'$1'"' -r src/
}

radius-genredis() {
	local namespace=$1
	shift
	local avps=$@

	for avp in ${avps[*]}; do
		avp_str="$(echo $avp | tr "[A-Z]" "[a-z]" | tr "-" "_")"
cat <<EOF
# avp: ${avp}
${namespace}.get_${avp_str} {
    update {
       &${avp} := "%{redis_cache:HGET \"%{Acct-Session-Id}\" \"$avp\"}"
       &${avp} -= ""
    }
}

${namespace}.set_${avp_str} {
    if (&${avp}) {
        "%{redis_cache:HSET \"%{Acct-Session-Id}\" $avp \"%{$avp}\"}"
    }
}

EOF
	done
}

git-commit-all-as-Update() {
	git status | awk '/modified/ { printf("git ci -m \"Update %s\" %s\n",$2,$2); }'
}

git-commit-fixup() {
	git status | grep "modified:" | while read _notinuse _file; do
		_hash=$(git log --oneline --pretty=format:"%h" -1 $_file)
		echo "git commit --fixup $_hash $_file"
	done

}
git-update-from-upstream() {
    set -fx
    git fetch --all
    git pull upstream
    set +fx
}

git-update-from() {
    if [ -z "$1" ]; then
        echo "Qual branch?"
        return
    fi
}

android-toolchain-config() {
    echo "<android-toolchain-config>"
    ls -1 ${ANDROID_TOOLCHAIN}
    echo "</android-toolchain-config>"

    echo -n "Qual toolchain deseja utilizar? "
    read opt
    echo "Utilizando a '$opt'"

    export PATH="$PATH_OLD"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/$opt/prebuilt/linux-x86_64/bin/"

    echo "Novo \$PATH: $PATH"
}

dpkg-purge-all()
{
    dpkg --list |grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
}

screen-killtudo () 
{ 
    wins=($(screen -ls | awk '/Detac/ { print $1 }'));
    for i in ${wins[*]};
    do
        echo "screen: Finalizando $i";
        screen -S "$i" -X quit;
    done
}

ssh-alog() {
    ssh -l jorge.pereira $1.alog.mobicare.com.br
}

update-alias()
{
	if [ ! -f $HOME/.bash_alias ];then
		echo "AVISO: Arquivo de alias invalido!"
		exit 0
	fi

	mv -fv $HOME/.bash_alias $HOME/.bash_alias.old
	alias 1> $HOME/.bash_alias 2>&-
	source $HOME/.bash_alias
}

# edita o arquivo personalizado de alias
edit-alias()
{	
	if [ ! -f $HOME/.bash_alias ];then
		echo "AVISO: Arquivo de alias invalido!"
		exit 0
	fi

	vi $HOME/.bash_alias
    unalias -a
	source $HOME/.bash_alias
}

# edita este arquivo
edit-functions()
{
	if [ ! -f $HOME/.bash_functions ];then
		echo "AVISO: Arquivo de alias invalido!"
		exit 0
	fi

	vi $HOME/.bash_functions
	source $HOME/.bash_functions
}

scp-to-casa() {
    to=$1
    shift
    echo "Copiando '$@' para $to"
    scp $@ root@jpereira.homeunix.org:$to
}

debian-update() {
    echo "Atualizando..."
    apt-get  update 
    apt-get -fy dist-upgrade
    apt-get -fy upgrade
}

man() {
    # begin blinking
    # begin bold
    # end mode
    # end standout-mode
    # begin standout-mode - info box
    # end underline
    # begin underline

    env LESS_TERMCAP_mb=$(printf "\e[1m") \
        LESS_TERMCAP_md=$(printf "\e[1;32m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;37m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;33m") \
        man "$@"
}

function html_onlyField()
{
    local str="$1="

    grep "$str" $2 | sed "s/.* $str\"//g; s/\".*$//g; /^$/d" | sort -n | uniq
}

#function ipc_clean() {
	#echo -n "(*) Cleaning semaphores..."
	#ipcs -s | awk '/[0-9]/ { print $2}' | while read a; do ipcrm -s $a; done
	#echo "ok"
#}

html_scape()
{
	cat /dev/stdin | sed 's/%5f/_/g; s/%5b/[/g; s/%5d/]/g'
}

gdb_attach_by_pid()
{
	if [ $# -lt 1 ];then
		echo "Usage: $0 <pid> <gdb commands>"
		return
	fi

	pid=$1
	bin="$(readlink /proc/${pid}/exe 2>&-)"
	
	if [ -z $bin ]; then
		echo "error: faltou passar o pid?"
		return
	fi
	shift

	echo "Carregando gdb para o binario '$bin' com PID:$pid"
	gdb $bin $pid $@
}

gdb_attach_trans()
{
	trans_pid=$(pgrep -u $USER trans | sed '1d')
	gdb_attach_by_pid $trans_pid $@
}

function _conf_complete() {
	local cur=${COMP_WORDS[COMP_CWORD]}

	COMPREPLY=($(compgen -W '$(find conf/bconf/bconf.txt.* | cut -d "/" -f 3 | cut -d "." -f 3)' -- $cur))
}

my-addalias()
{
    echo "alias $@" >> ~/.bash_alias
    source ~/.bash_alias
}

my-set-old-ps1()
{
    export PS1="[\u@\h \W]\\$ "
}

my-valgrind()
{
    local log=$(basename $1).valgrind.log
    export G_SLICE=always-malloc
    export G_DEBUG=gc-friendly  

    valgrind -v --tool=memcheck --leak-check=full --num-callers=40 --log-file="${log}" $@
}

my-ver()
{
    lynx -dump -head http://$1
}

cd.real()
{
   cd $(pwd -P); ls -l 
}
my-show-size-of-my-home()
{
    cd ~ && {
        ls -a | grep -v "^\\.\\.\?$" | xargs du -hs | sort --key=1
    }
}

# utilizado para reiniciar servico
my-service-restart()
{
    if [ -z "$*" ];then
        echo "Usage: `basename $0` <servico>"
    else
        for prog in $*; do {
            echo -n "Restarting ${prog} ..."
            sudo /etc/init.d/${prog} restart
            echo "ok"
        } done
    fi
}

# clean of backups
my-nobacks()
{
    find . -name "*~"  -exec rm -rfv {} ";"
    find . -name ".*~" -exec rm -rfv {} ";"
}

# sabe o tamanho do home
my-size-of-home()
{
    rm -f ~/mysize.txt 
    ls -a ~ | while read _file_; do {
        du -hs ${_file_}
    } done | sort -n --key=1 > /tmp/mysize-$$
    mv -f /tmp/mysize-$$ ~/mysize.txt
}

# clean buff of memory
my-clean-buffersmemory()
{
  echo "(*) Limpando cache..."
  sudo sysctl -w vm.drop_caches=1
  sudo sysctl -w vm.drop_caches=2
  sudo sysctl -w vm.drop_caches=3
}

# faz busca por um bin nos PATH's
findbin()
{
    local ACHOU=12

    if [ -z "$1" ];then
        echo "Usage: $0 <comando>"
    else
        ls ${PATH//:/ } 2>&- | grep -i $1 | sort -n | uniq | \
		while read _file; do 
			if ( (which ${_file} 1> /dev/null 2>&1));then
				echo $(which ${_file})
			else 
				echo ":${_file}"
			fi
		done | sort -n
		
		if [ "${ACHOU}" = "false" ];then
			echo "Nada encontrado referente a ($1) no \$PATH."
			exit 1
		fi
    fi
}

# exibe o ip real para internet
my-ip()
{
  #_ip=$(lynx -dump http://www.ossec.net/userinfo/ | sed '/Ip Address/!d; s/\(.*:\| \)//g;')
  _ip=$(lynx -dump http://www.myip.com.br/ | sed '/Seu IP:/!d; s/.*: //g')
  echo "Meu IP: http://${_ip}:8080$1"
}

# limpa os arquivos de log
clean-var-log()
{
  find /var/log -maxdepth 1 -type f | \
  while read l
  do 
    > $l
  done
}

edit-this()
{
    if [ -f $(which $1) ];then
        vi $(which $1)
    else
        echo "O Arquivo $1 nao existe fera! :("
    fi
}

# executa o comando cp com um progress bar
cp_p()
{
   set -e
   strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
      | awk '{
	    count += $NF
            if (count % 10 == 0) {
               percent = count / total_size * 100
               printf "%3d%% [", percent
               for (i=0;i<=percent;i++)
                  printf "="
               printf ">"
               for (i=percent;i<100;i++)
                  printf " "
               printf "]\r"
            }
         }
         END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
}

# edita o bashrc
edit-bash_profile()
{
	vi ~/.bash_profile
	source ~/.bash_profile
}

# edita o vimrc
edit-vimrc()
{
    vi ~/.vimrc
}
# edita a var PATH em bashrc
edit-path()
{
	vi ~/.bashrc +/^PATH
	source ~/.bashrc
}

# recarrega o bash_functions
reload-functions()
{
	source ~/.bash_functions
}

# recarrega o bashrc
reload-bash_profile()
{
	source ~/.bash_profile
}

#remover servicos
service-remove()
{
	for i in $@; do
	{
		sudo update-rc.d -f $i remove
        [ -f "/etc/init.d/$i" ] && sudo invoke-rc.d $i stop
	}
	done
}
	
# converter jpg para boot image
wallpaper2bootimage()
{
	convert -resize 640x480 -colors 14 $1 splashimage.xpm && gzip splashimage.xpm
}

