# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Fri Jun 28 14:50:08 2019
# Created: Mon 01 Jun 1999 01:22:10 AM BRT
##

#
#	fr. (FreeRADIUS helper commands)
#
# Usage: cd freeradius-server.git/share && fr.dictinary-check ../src/
#
function fr.dictinary-check() {
	local _src="${1:-../src}"

	echo "# Checking missing 'dictionary.*' in ./dictionary"

	for _d in dictionary.*; do
		[ ! -f "$_d" ] && continue

		# Is it ready included?
		# I know,log(n). But, don't care about performance.
		grep -q "\$INCLUDE ${_d}$" dictionary dictionary.* && continue

		# Check if exist some source-code referencing/loading the dictionary
		# yep, its is simple. fine for now.
		if [ -d "$_src" ]; then
			grep -q "\"${_d}" -r "${_src}" 2>&- && continue
		fi

		echo "\$INCLUDE $_d"
	done | grep -v -E "\.(dhcp|vqp|illegal)" | sort -n
}

#
#	show-*
#
show-cpu-infos() {
	if [ "$OS" = "Darwin" ]; then
		if ! osx-cpu-temp -Ccgf; then
			brew install osx-cpu-temp
		fi
	else
		echo "not found"
	fi
}

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
	$_DD if=/dev/zero of=${_f} bs=1M count=8096 status=progress 

	sync
	echo

	echo "# Reading the content '$_f'" 
	$_DD if=${_f} of=/dev/null bs=1M count=8096 status=progress 

	rm -f ${_f}

	echo
}

show-size-of-my-home() {
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
	local iface="${1:-any}"
	shift
	local args="$@"

	set -fx
	sudo tcpdump -nve -i ${iface} -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0) and (not host 54.94.230.94) $args'
	set +fx
}

#
# 	docker-*
#
docker-run-prev-container() {
	set -fx
	local prev_container_id="$(docker ps -aq | head -n1)"
	docker commit "$prev_container_id" "prev_container/$prev_container_id"
	docker run -it --entrypoint=bash "prev_container/$prev_container_id"
	set +fx
}

docker-cleanup-containers-untagged() {
	set -fx
	docker images -a | awk '/<none>/ { print $3}' | xargs docker rmi -f
	set +fx
}

docker-cleanup-instances-stopped() {
	set -fx
	docker ps -a --format '{{.Names}} {{.Status}}' | while read docker_image docker_status; do
		if echo "$docker_status" | grep -iq "exited"; then
			echo -n "(*) Removing: "
			docker rm -f $docker_image
		fi
	done
	set +fx
}

docker-cleanup-instances-all() {
	docker ps -a --format '{{.Names}}' | while read docker_image; do
		docker rm -f $docker_image
	done
}

docker-stop-instances() {
	docker ps --format '{{.Names}}' | while read docker_pid; do
		echo -n "(*) Stopping: "
		docker stop $docker_pid
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
update-photos-date-to() {
	local _d="$(date '+%Y-%m-%d %H:%M:%S')"

	echo "# Commands! Use '| sh' to execute"

	echo exiftool -AllDates=\"$_d\" -overwrite_original $@
}

function update-resolvconf2google8888() {
	sudo tee /etc/resolv.conf <<EOF
# Created at $(date) by update-resolvconf2google8888
nameserver 8.8.8.8
nameserver 8.8.8.4
EOF

	echo "------------- /etc/resolv.conf"
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
alias ssh-cleanup-sessions="cleanup-ssh-sessions"

cleanup-snap() {
	snap list --all | awk '/disabled/{print $1, $3}' | \
	while read snapname revision; do
		sudo snap remove "$snapname" --revision="$revision"
	done
}

function vim-to-html() {
   local in="$1"

   if [ -z "$in" ]; then
       echo "Usage: $0 </path/caipirinha.c>"
       return
   fi

   echo "# Converting $in to HTML ${in}.html" 

   vim -c "let g:html_no_progress = 1" -c "set bg=dark" -c TOhtml -c "w!" -c 'qa!' $in
}

#
#	git-*
#
alias git-enable-debug="export GIT_CURL_VERBOSE=1 GIT_TRACE=1"
alias git-disable-debug="unset GIT_CURL_VERBOSE GIT_TRACE"

git_parse_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

git-push-all-origin-branches() {
	git branch -l | while read _branch; do
		echo "# ~> Pushing the branch origin/$_branch"
		git push -f origin $_branch
	done
}

git-convert-remote2ssh() {
	git remote -v | \
	awk '/\(fetch\)$/ {
		gsub("https://github.com/", "git@github.com:", $2)
		printf("git remote set-url %s %s\n", $1, $2)
	}'
}

git-commit-as-update() {
	echo "# Use '| sh' to execute"

	git status | awk '/modified/ { printf("git ci -m \"Update %s\" %s\n",$2,$2); }'
}

git-commit-as-fixup() {
	local _deep="${1:-10}"
	local curr_branch="$(git describe --all @{0} | sed 's@^heads/@@g')"
	local prev_branch="$(git describe --all @{-1} | sed 's@^heads/@@g')"
	local _e=echo

	[ "$1" = "run" ] && _e=eval

	git status | grep "modified:" | while read _notinuse _file; do
		_hash=$(git log --oneline --pretty=format:"%h" -1 $_file)
		$_e "git commit --fixup $_hash $_file"
	done

	$_e "git rebase -i --autosquash ${prev_branch}~${_deep}"
	$_e "git pull --rebase upstream ${prev_branch}"
	$_e "git push -f origin $curr_branch"
}

#
#	cleanup-*
#
cleanup-screen-sessions() {
    screen -ls | awk '/De/ { print $1 }' | while read _s; do
        echo "# ~~> screen: Removing $_s";

        screen -S "$_s" -X quit;
		screen -wipe $_s
    done
}

#
#	edit-*
#
_edit-config() {
	local _f="$1"
	local _r="$2"

	if [ ! -f "$_f" ];then
		echo "WARNING: The file $_f is not found"
		return 1
	fi

	echo "# ~> Calling: $EDITOR $_f"

	[ -n "$EDITOR" ] && eval "$EDITOR ${EDITOR_OPTS[*]} $_f" || vim $_f

	# Need to reload?
	[ -n "$_r" ] && eval "source ~/.bashrc"

	echo "exiting."
}

_set-edit2alias() {
	local _file="$1"
	local _name="$2"
	
	[ -z "$_name" ] && _name="$(basename $_file | sed 's/^\.//g')"

	eval "alias edit-${_name}='_edit-config ${_file}'"
}

#
#	Create alias to directories. (super lazzyyyyyy)
#
_set-dir2alias() {
	local _path="$1"
	local _name="$(basename $_path | sed 's/\.git//g')"

	[ ! -d "$_path" ] && return

	eval "alias cd.${_name}='echo \"# cd $_path\"; cd $_path; ls -l'"

	for _d in $(ls ${_path}); do
		_dir="${_path}/${_d}"
		[ ! -d "$_dir" ] && continue
		
		eval "alias cd.${_name}.${_d}='echo \"# cd $_dir\"; cd $_dir; ls -l'"
	done
}

#
#	debian-* / dpkg-*
#
dpkg-purge-all() {
    sudo dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
}

debian-update() {
    echo "# Udating the system."

    sudo apt update
    sudo apt -fy dist-upgrade
    sudo apt -fy upgrade
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
gdb-attach-by-pid() {
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
my-nobacks() {
	echo "# Removing all '*~' and '.*~' in $PWD"

    find $PWD -name "*~"  -exec rm -fv {} ";"
    find $PWD -name ".*~" -exec rm -fv {} ";"
}
alias noback="my-nobacks"

# clean buff of memory
my-clean-buffersmemory() {
    echo "(*) Cleaning cache..."

    sudo sysctl -w vm.drop_caches=1
    sudo sysctl -w vm.drop_caches=2
    sudo sysctl -w vm.drop_caches=3
}

#
#	Look for bin in $PATH
#
find-bin() {
    if [ -z "$1" ];then
        echo "Usage: $0 <comando>"
        return
    fi

	ls ${PATH//:/ } 2>&- | grep -i $1 | sort -n | uniq | \
	while read _file; do 
		if which ${_file} 1> /dev/null 2>&1;then
			echo $(which ${_file})
		else 
			echo ":${_file}"
		fi
	done | sort -n
}

#
#	cp-progressbar
#
# executa o comando cp com um progress bar
cp-progressbar() {
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

