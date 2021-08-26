# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Tue Aug 24 10:57:10 2021
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
#	asciidoctor
#
adoc-ls2link() {
	ls -1 | while read _f; do
		[ "$_f" = "index.adoc" ] && continue

		if [ -d "$_f" ]; then
			#echo "* link:$_f[$_f]"
			echo "* $_f"
			ls -1 "$_f" | while read _d; do
				echo "** link:$_f/$_d[$_d]"
			done
		else
			echo "* link:$_f[$_f]"
		fi
	done
}

# Cleanup from markup convertion.
adoc-cleanup() {
	cat $1 | sed '
	s/\.\.\.\./\`\`\`/g;
	s/\`\+/\`/g;
	s/+\`/\`/g;
	' > ${1}.$$
	mv -f ${1}.$$ ${1}
}

#
#
#
webp2png() {
	ls *.webp | while read a; do
		echo "dwebp -o \"${a/webp/png}\" \"$a\""
	done
}

#
#	show-*
#
show-process-memory-usage() {
	ps -eo size,pid,user,command --sort -size | \
	    awk '{
		    hr=$1/1024;
		    printf("%13.2f Mb ",hr)
	    }
	    {
		    for ( x=4 ; x<=NF ; x++ ) {
			    printf("%s ",$x)
		    }
		    print ""
	    }'
}

show-openssl-cert-infos() {
	for i in $@; do
		set -fx
		openssl x509 -in $i -noout -text
		set +fx
	done
}

show-cpu-cores() {
	if [ "$OS" = "Darwin" ]; then
		sysctl -n hw.logicalcpu
	else
		grep "cpu family" /proc/cpuinfo | wc -l
	fi
}

show-random-ip() {
	echo $(dd if=/dev/urandom bs=4 count=1 2>/dev/null | \
	            od -An -tu1 | sed -e 's/^ *//' -e 's/  */./g; s/\.$//g')
}

show-cpu-temp() {
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
    	ls -a | sort -n |  while read _f; do
		[ "$_f" = ".." ] && continue
		sudo du -hs "$_f"
	done
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

docker-cleanup-images-none() {
	docker images | awk '/^<none>/{print $3}' | xargs docker rmi -f
}

docker-cleanup-containers-untagged() {
	set -fx
	docker images -a | awk '/<none>/ { print $3}' | xargs docker rmi -f
	set +fx
}

docker-cleanup-instances-stopped() {
#	set -fx
	docker ps -a --format '{{.Names}} {{.Status}}' | while read docker_image docker_status; do
		if echo "$docker_status" | grep -iq "exited"; then
			echo -n "(*) Removing: "
			docker rm -f $docker_image
		fi
	done
#	set +fx
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

git-branch-reset() {
	set -fx
	git co master
	git branch -D $1
	git co -b $1
	set +fx
}

open-git-changed-with-subl() {
	subl $(git st -s | sed 's/M//g' )
}

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

git-cleanup-branch() {
	local _rem_branches=""
	local _loc_branches=""

	for _b in $@; do
		_rem_branches="$_rem_branches :${_b}"
		_loc_branches="$_loc_branches ${_b}"
	done

	if [ -z "${_rem_branches[@]}" ]; then
		echo "git-cleanup-branch: Nothing to do!"
		return
	fi

	git branch -D ${_loc_branches[@]}

	for _b in ${_rem_branches[@]}; do
		git push -f origin $_b
	done

	git fetch --all --force -pn
}

git-rebase-fixup-autosquash() {
	local _d="${1:-30}"

	#git stash

	GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash HEAD~$_d

	#git stash apply
}

git-fixup-with-last-commit() {
	local _last_commit="$(git log --pretty=format:%h -1)"
	local _files="${@:-.}"

	set -fx
	git commit --fixup $_last_commit ${_files[*]}

	GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash HEAD^^
	set +fx
}

git-fixup-by-files-last-commit() {
	git status -s | awk '{if ($1 == "M") print $2}' | while read f; do
		local _last_commit="$(git log --pretty=format:%h -1 $f)"
		echo git commit --fixup $_last_commit ${f}
	done
}

git-show-lost-found() {
	git fsck --full --no-reflogs --unreachable --lost-found | \
		awk '/commit/ { print $3}' | xargs -n 1 git log -n 1 --pretty=oneline
}

git-commit-as-fixup() {

	local curr_branch="$(git describe --all @{0} | sed 's@^heads/@@g')"
	local prev_branch="$(git describe --all @{-1} | sed 's@^heads/@@g')"
	local _e=echo

	[ -z "$curr_branch" ] && curr_branch="master"

	[ "$1" = "run" ] && { _e=eval; shift; }

	local _deep="${1:-10}"

	git status | grep "modified:" | while read _notinuse _file; do
		_hash=$(git log --oneline --pretty=format:"%h" -1 -- $_file)
		$_e "git commit --fixup $_hash $_file"
	done

	$_e "GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash HEAD~${_deep}"
	$_e "git pull --rebase upstream ${prev_branch}"
	#$_e "git pull --rebase upstream"
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
my-sum-dotplus8() {
	grep -o "^\d.[0-9]\{1,9\}" $1 | awk '{ n+=$1 } END { printf("Total: %f\n", n); }'
}

my-ip() {
	echo "# dig +short myip.opendns.com @resolver1.opendns.com $@"
	dig +short myip.opendns.com @resolver1.opendns.com $@
}

my-vm-increase-vmdk() {
	local _vm="${1:-foo}"
	local _size="30720"

cat <<EOF
	VBoxManage clonehd ${_vm}.vmdk ${_vm}.vdi --format VDI --variant Standard

	mv ${_vm}.vmdk ${_vm}.vmdk.orig

	VBoxManage modifyhd ${_vm}.vdi  --resize ${_size}

	VBoxManage clonehd ${_vm}.vdi ${_vm}.vmdk --format VMDK --variant Standard

	# Check and delete ${_vm}.vmdk.orig
EOF

}

my-ssh-tcpdump2wireshark() {
	local _host="$1"
	local _iface="$2"
	local _filter="$3"

	if [ -z "$_filter" ]; then
		echo "Usage: my-ssh-tcpdump2wireshark <ip/host> <iface> <tcpdump filter>"
		echo
		echo "e.g: my-ssh-tcpdump2wireshark root@router.lan br-lan 'ether host 00:16:3e:2f:98:47'"
		return
	fi

	echo "DEBUG: host='$_host', iface='$_iface', filter='$_filter'"
	set -fx
	ssh $_host tcpdump -U -i $_iface -w - \"$_filter\" | wireshark -i -
	set +fx
}

my-hexcount() {
	echo "# hexdump"
	echo "$@" | tr " " "\n" | paste - - - - - - - - 

	_tot=$(echo "$@" | tr " " "\n" | wc -l)
	_toth=$(printf "%#x" $_tot)
	echo
	echo "# Total: $_tot ($_toth)"
}

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

my-extract-tgz() {
	for _t in $@; do
		_dir="$(basename $_t | sed 's/\.tar.gz//g; s/\.tgz//g')"

		mkdir -p $_dir
		echo "# Extracting $_t in $_dir"
		tar xzvf $_t -C $_dir
	done
}

my-extract-tar() {
	for _t in $@; do
		_dir="$(basename $_t | sed 's/\.tar//g')"

		mkdir -p $_dir
		echo "# Extracting $_t in $_dir"
		tar xvf $_t -C $_dir
	done
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
#	ipv6
#
ipv62hex() {
	echo "# ~> Converting $1 to hexa"

	sipcalc $1 | sed '/Compressed addres/!d; s/.*- //g; s/://g; s/^/0x/g'
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

#
# ffmpeg
#
my-ffmpeg-reduce() {
	for m in $@; do
		echo "# Reducing $m"
		ffmpeg -i $m -vcodec libx265 -crf 20 reduced-${m}
	done
}

#
# btc
#
btc-show-price() {
	_dolar=$1
	_btcs=$2

	if [ -z "$_dolar" ]; then
		echo "btc-show-price dolar-price"
		return
	fi

	echo "R\$1 = R\$${_dolar}"
	echo

	_d=10
	while [[ $_d -lt 100 ]]; do
		_p=$(bc <<< "$_d * $_dolar");
		avarage=""
		if [ -n "$_btcs" ]; then
			_amount=$(bc <<< "($_btcs * ${_p}) * 100")
			avarage="(${_btcs}btcs x R\$${_p} +/- R\$${_amount})"
		fi

		echo "BTC\$${_d}000 -> R\$${_p}00 $avarage"

		let "_d+=2"
	done
}

#
# fr-
#
fr-fromlog2hex() {
	echo "# Reading from /dev/stdin"
	_log=$(cat /dev/stdin | sed 's/^.*: //g' | tr '\n' ' ' | tr -d ' ')
	fr-hex2code "$_log"
}

fr-hex2code() {
	_hex="$1"
	_tot=0

	if [ -f "$_hex" ]; then
		echo "# Loading $_hex file"
		_hex="$(xxd -p $_hex | tr -d '\n')"
	fi

	if [ "$2" = "rev" ]; then
		echo "# Put in reverse mode"
		_hex="$(echo $_hex | rev)"
	fi

	echo "# Copied to clipboard, use with command+v"
	_tot="$(echo $_hex | fold -w2 | wc -l | tr -d ' ')"
	_o="$(echo $_hex | fold -w2 | tr '\n' ' ')"

	echo "# tot=$_tot bytes"
	echo "decode-xxx $_o"
	echo "match Attr-125 = 0x$(echo $_o | tr -d ' ')"
	echo -n $_o | pbcopy
}

#
#	QNAP
#
qnap-mysql-connect() {
	local _host=dev-mysql.lan

	echo "(*) Connecting to $_host"
	mysql -u root -p -h $_host $@
}
