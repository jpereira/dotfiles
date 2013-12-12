#!/bin/bash
# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Qui 12 Dez 2013 18:55:04 BRST
# Created: Mon 01 Jun 1999 01:22:10 AM BRT
##

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
export PATH

function scp-to-casa() {
    to=$1
    shift
    echo "Copiando '$@' para $to"
    scp $@ root@jpereira.homeunix.org:$to
}

function debian-update() {
    apt-get update
    apt-get dist-upgrade
    apt-get upgrade
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

function html_onlyField() {
    local str="$1="

    grep "$str" $2 | sed "s/.* $str\"//g; s/\".*$//g; /^$/d" | sort -n  | uniq
}

function fix_test() {
    in=${1:-.get_url.out}
    cat $in | sed 's/\(dev\|dv2\).srv.office:[0-9][0-9][0-9][0-9][0-9]/{{.*}}/g; 1s/^.*$/{{.*}}/g'
}

function fix_test_diff() {
    local in=${2:-.get_url.out}
    local out=$1
    
    if [ $# -lt 1 ]; then
        echo "Usage: fix_test_diff tests/arquivo-teste.out [.get_url.out]"
        return
    fi
    
    if [ ! -f "$out" ]; then
        echo "oops! arquivo $out nao encontrado."
        return
    fi
    
    sed 's/, /,\n/g' -i $out
    vimdiff -c 'windo set wrap' <(sed 's/, /,\n/g' $in) $out
    sed ':a;N;$!ba;s/,\n/, /g' -i $out
}

function ipc_clean() {
	# limpa os semaforos
	echo -n "(*) Cleaning semaphores..."
	ipcs -s | awk '/[0-9]/ { print $2}' | while read a; do ipcrm -s $a; done
	echo "ok"
}

make-run-selenium-test()
{
	make rc rd rs-load selenium-start $@
}

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

nc_trans()
{
	cat /dev/stdin | nc localhost 26805
}

psql_regress(){
	psql --no-align --field-separator=, --pset footer $@
}

# Opens one or more bconf files in the same vim
function conf() {
	if [ $# -eq 0 ]; then
		echo "Please specify a file"
	elif [ $# -eq 1 ]; then
		local file="conf/bconf/bconf.txt.$1"

		if [ -a $file ]; then
			vim $file
		else
			echo "Unknown file: $file"
		fi
	else
		local params=$@
		eval vim -p conf/bconf/bconf.txt.{${params// /,}}
	fi
}
# Tab completion for the conf command
function _conf_complete() {
	local cur=${COMP_WORDS[COMP_CWORD]}

	COMPREPLY=($(compgen -W '$(find conf/bconf/bconf.txt.* | cut -d "/" -f 3 | cut -d "." -f 3)' -- $cur))
}

function my-sync-scripts-from-jorgepereira()
{
 from="http://blog.jorgepereira.com.br/wp-content/dist/scripts/"

 cd ~ && \
 wget -c $(lynx -dump http://blog.jorgepereira.com.br/wp-content/dist/scripts/ | sed '/http:\/\//!d; /dot\./!d; s/.* //') && \
 ls dot.* | while read a; do mv -fv $a "$(echo $a | sed 's/dot//g')"; done
}

my-addalias()
{
    echo "alias $@" >> ~/.bash_alias
    source ~/.bash_alias
}

my-set-simple-path()
{
  export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
}

my-set-old-ps1()
{
        export PS1="[\u@\h \W]\\$ "
}

my-valgrind()
{
    log=$(basename $1).valgrind.log
    export G_SLICE=always-malloc
    export G_DEBUG=gc-friendly  

    valgrind -v --tool=memcheck --leak-check=full --num-callers=40 --log-file=${log} $@

}

my-df-devices()
{
    df -Th / /boot /home /coisas /media/Movies /media/Musics /media/WindowsXP 2>&-
}

ver()
{
    lynx -dump -head http://$1
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

# liga o capslock
my-start-of-all-capslock()
{
# Teclado (NUMLOCK)
    INITTY="1 2 3 4 5 6 7 8 9 10 11" 
    for tty in $INITTY; do {
       setleds -D +num < /dev/tty$tty
       setleds -D -num < /dev/tty$tty
       setleds -D +num < /dev/tty$tty
    } done
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

# gravar cd
my-cdrecord()
{
  if [ $# -lt 1 ];then
    echo "Usage: $(basename $0) <arquivo iso>"
    exit 1
  else
    cdrecord dev=ATAPI:/dev/hdc -pad -speed=32 -eject -data -force -v $1
  fi
}

# clean buff of memory
my-clean-buffersmemory()
{
  echo "(*) Limpando cache..."
  sudo sysctl -w vm.drop_caches=1
  sudo sysctl -w vm.drop_caches=2
  sudo sysctl -w vm.drop_caches=3
}

# kill
kill-evolution()
{
  ps aux | grep evolution | awk '{print $2}' | xargs kill -9 1> /dev/null 2>&1
  TASK=$?

  if [ ${TASK} -eq 1 ];then
    echo "N�o existe processo do evolution sendo executado..."
  fi
}

# faz busca por um bin nos PATH's
findbin()
{
 ACHOU=12

  if [ -z "$1" ];then
    echo "Usage: $0 <comando>"
	else
    echo $PATH | sed "s/:/ /g" | xargs ls 2> /dev/null | grep -i $1 | \
		sort -n | uniq | \
		while read _file; do 
			if ( (which ${_file} 1> /dev/null 2>&1));then
				echo $(which ${_file})
			else 
				echo ":${_file}"
			fi
		done | sort -n
		
		if [ "${ACHOU}" = "false" ];then
			echo "Nãda encontrado referente a ($1) no \$PATH."
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

# faz uma copia do cd
copyCdrom2Iso()
{
	arg0=copyCdrom2Iso
	if [ -z $1 ];then
		echo "Usage: $arg0 <device> <destino nome do arquivo.iso"
		echo "Ex:"
		echo "$arg0 /dev/hdc arquivo.iso"
		echo
		return
	fi

	dd if=$1 of="$2" bs=2048
	echo "Done!"
}

# download de files do youtube
downtube()
{
	mkdir -p ~/youtube
	cd ~/youtube
	youtube-dl -o $1 $2
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

# Criar uma copia do cd atual para uma imagem ISO
cdrom2iso()
{
	dd if=/dev/cdrom of=CDROM-file.iso bs=1024
}

# criar uma isso apartir de um diretorio
criarISO()
{
	NOME=$1
	shift

	mkisofs -r -o $NOME-file.iso $@
}

# Atualizando alias
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

