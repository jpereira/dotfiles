# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Sat 22 Jun 2019 06:50:40 PM -03
# Created: Mon 01 Jun 1999 01:22:10 AM BRT
##

#
#	show-*
#
show-disk-speed() {
	local _p=${1:-$PWD}
	local _f="${_p}/tempfile.$$"

	rm -f $_f

	sync

	if [ "$OS" = "Linux" ]; then
		echo "# Cleanup kernel cache"
		sudo /sbin/sysctl -w vm.drop_caches=3
	fi

	echo
	echo "# Creating the file '$_f'"
	dd if=/dev/zero of=${_f} bs=1M count=4096

	sync
	echo
	echo "# Reading the content '$_f'" 
	sudo dd if=${_f} of=/dev/null bs=1M count=4096

	rm -f ${_f}

	echo
}

show-size-of-my-home()
{
    cd ~ && {
        ls -a | grep -v "^\\.\\.\?$" | xargs du -hs | sort --key=1
    }
}

show-wifi() {
	watch -n2 'nmcli -f "CHAN,BARS,SIGNAL,SSID" d wifi list'
}

#
#	tcpdump-*
#
# filtra pacotes http
function tcpdump-http() {
	local iface="${1:-eth0}"
	shift
	local args="$@"

	set -fx
	tcpdump -nve -i ${iface} -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0) and (not host 54.94.230.94) $args'
	set +fx
}

#
# 	docker-*
#
docker-run-prev-container() {
	set -fx

	prev_container_id="$(docker ps -aq | head -n1)"
	
	docker commit "$prev_container_id" "prev_container/$prev_container_id"
	docker run -it --entrypoint=bash "prev_container/$prev_container_id"

	set +fx
}

docker-cleanup-unknown-images() {
	docker images -a | awk '/<none>/ { print $3}' | xargs docker rmi -f
}

docker-stop-instances() {
	docker ps --format '{{.Names}}' | while read docker_pid; do
		echo -n "(*) Stopping: "
		docker stop $docker_pid
	done
}

docker-cleanup-instances-stoppeds() {
	docker ps -a --format '{{.Names}} {{.Status}}' | while read docker_image docker_status; do
		if echo "$docker_status" | grep -iq "exited"; then
			echo -n "(*) Removing: "
			docker rm -f $docker_image
		fi
	done
}

docker-cleanup-instances() {
	docker ps -a --format '{{.Names}}' | while read docker_image; do
		#docker stop $docker_image
		echo docker rm -f $docker_image
	done
}

docker-show-ips() {
	docker ps --format '{{.Names}}' | while read docker_image; do
		_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $docker_image)

		echo "docker_image: $docker_image ipaddr: $_ip"
	done | sort -n -k4 | column -t
}

docker-run-bash-in() {
	docker exec -it $1 /bin/bash
}

#
#	update-*
#
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

update-photos-date-to() {
	local _d="$(date '+%Y-%m-%d %H:%M:%S')"
	#shift

	echo exiftool -AllDates=\"$_d\" -overwrite_original $@
}

function update-resolvconf2google8888 (){
	echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
	cat /etc/resolv.conf
	echo "------------- testing"
	ping -c2 www.google.com.br
}

#
#	cleanup-*
#
cleanup-ssh-sessions() {
	rm -fv ~/.ssh/sessions/*
}

cleanup-snap() {
	snap list --all | awk '/disabled/{print $1, $3}' | \
	while read snapname revision; do
		sudo snap remove "$snapname" --revision="$revision"
	done
}

git_parse_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
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

#
#	git-*
#
git-push-all-local-branches() {
	git branch -l | while read _branch; do
		echo "~> Pushing the branch origin/$_branch"
		git push -f origin $_branch
	done
}

git-remote2ssh() {
  git remote -v | awk '/\(fetch\)$/ {
    gsub("https://github.com/", "git@github.com:", $2)

    printf("git remote set-url %s %s\n", $1, $2)
  }'
}

git-doit-stash-clear-update-stashapply() {
	set -fx
	git stash clear
	git stash
	git prum
	git stash apply
	set +fx
}

git-commit-all-as-Update() {
	git status | awk '/modified/ { printf("git ci -m \"Update %s\" %s\n",$2,$2); }'
}

git-commit-fixup() {
	local curr_branch="$(git describe --all @{0} | sed 's@^heads/@@g')"
	local prev_branch="$(git describe --all @{-1} | sed 's@^heads/@@g')"
	local _e=echo

	[ "$1" = "run" ] && _e=eval

	git status | grep "modified:" | while read _notinuse _file; do
		_hash=$(git log --oneline --pretty=format:"%h" -1 $_file)
		$_e "git commit --fixup $_hash $_file"
	done

	$_e "git rebase -i --autosquash ${prev_branch}~10"
	$_e "git pull --rebase upstream"
	$_e "git push -f origin $curr_branch"
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

#
#	dpkg-*
#
dpkg-purge-all()
{
    dpkg --list |grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
}

#
#	cleanup-*
#
cleanup-screen-sessions() 
{ 
    screen -ls | awk '/Detac/ { print $1 }' | while read _s;
    do
        echo "~~> screen: Finalizando $_s";
        screen -S "$_s" -X quit;
	screen -wipe $_s
    done
}

#
#	edit-*
#
_edit-config()
{
	local _f="$1"
	if [ ! -f "$_f" ];then
		echo "WARNING: The file $_f is not found"
		return 1
	fi

	echo "~> Calling: $EDITOR $_f"

	[ -n "$EDITOR" ] && eval "$EDITOR $_f" || vim $_f

	# Need to reload?
	if echo $_f | grep -i bash; then
		source $_f
	fi

	echo "exiting."
}

alias edit-sshconfig="_edit-config $HOME/.ssh/config"
alias edit-gdbinit="_edit-config $HOME/.gdbinit"
alias edit-gitconfig="_edit-config $HOME/.gitconfig"
alias edit-screenrc="_edit-config $HOME/.screenrc"
alias edit-vimrc="_edit-config $HOME/.vimrc"

alias edit-bash_alias="_edit-config $HOME/.bash_alias"
alias edit-bash_functions="_edit-config $HOME/.bash_functions"
alias edit-bash_profile="_edit-config $HOME/.bash_profile"
alias edit-bashrc="_edit-config $HOME/.bashrc"

#
#	debian-*
#
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

#
#	gdb-*
#
gdb-attach-by-pid()
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

#
#	my-*
#
my-nobacks()
{
    find . -name "*~"  -exec rm -rfv {} ";"
    find . -name ".*~" -exec rm -rfv {} ";"
}

# clean buff of memory
my-clean-buffersmemory()
{
  echo "(*) Cleaning cache..."
  sudo sysctl -w vm.drop_caches=1
  sudo sysctl -w vm.drop_caches=2
  sudo sysctl -w vm.drop_caches=3
}

#
# faz busca por um bin nos PATH's
#
find-bin()
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

#
#	cp-progressbar
#
# executa o comando cp com um progress bar
cp-progressbar()
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
