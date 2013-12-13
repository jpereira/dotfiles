# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Sex 13 Dez 2013 15:48:13 BRST
##

set history filename ~/.gdb_history
set history save
set history save on 
set print symbol-filename on
set print array on
set print pretty on
set print union on

def close_stdout
call close(1)
end

def disable_signals
    handle SIGUSR1 nostop noprint
    handle SIGUSR2 nostop noprint
    handle SIGWAITING nostop noprint
    handle SIGLWP nostop noprint
    handle SIGPIPE nostop
    handle SIGALRM nostop
    handle SIGHUP nostop
    handle SIGTERM nostop noprint
end

def fn
	focus next
end

def im
	info macro
end

def tap
	thread apply all bt full
end
