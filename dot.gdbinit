# Author: Jorge Pereira <jpereiran@gmail.com>
# Last Change: Mon Nov  8 18:01:56 2021
##

set startup-with-shell off

set history filename ~/.gdb_history
set history save
set history save on 
set print symbol-filename on
set print array on
set print pretty on
set print union on

#set detach-on-fork off
#set non-stop off
#set pagination off

#def close_stdout
#	call close(1)
#end

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

def debug-library
   set detach-on-fork off
   set schedule-multiple on
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

define ascii_char
    set $_c=*(unsigned char *)($arg0)
    if ( $_c < 0x20 || $_c > 0x7E )
        printf "."
    else
        printf "%c", $_c
    end
end
document ascii_char
    Print the ASCII value of arg0 or '.' if value is unprintable
end

define hex_quad
    printf "%02X %02X %02X %02X  %02X %02X %02X %02X",                          \
                   *(unsigned char*)($arg0), *(unsigned char*)($arg0 + 1),      \
                   *(unsigned char*)($arg0 + 2), *(unsigned char*)($arg0 + 3),  \
                   *(unsigned char*)($arg0 + 4), *(unsigned char*)($arg0 + 5),  \
                   *(unsigned char*)($arg0 + 6), *(unsigned char*)($arg0 + 7)
end
document hex_quad
    Print eight hexadecimal bytes starting at arg0
end

define hexdump
    printf "%08X : ", $arg0
    hex_quad $arg0
    printf " - "
    hex_quad ($arg0+8)
    printf " "

    ascii_char ($arg0)
    ascii_char ($arg0+1)
    ascii_char ($arg0+2)
    ascii_char ($arg0+3)
    ascii_char ($arg0+4)
    ascii_char ($arg0+5)
    ascii_char ($arg0+6)
    ascii_char ($arg0+7)
    ascii_char ($arg0+8)
    ascii_char ($arg0+9)
    ascii_char ($arg0+0xA)
    ascii_char ($arg0+0xB)
    ascii_char ($arg0+0xC)
    ascii_char ($arg0+0xD)
    ascii_char ($arg0+0xE)
    ascii_char ($arg0+0xF)

    printf "\n"
end
document hexdump
    Display a 16-byte hex/ASCII dump of arg0
end

define ddump
    printf "[%04X:%08X]------------------------", $ds, $data_addr
    printf "---------------------------------[ data]\n"
    set $_count=0
    while ( $_count < $arg0 )
        set $_i=($_count*0x10)
        hexdump ($data_addr+$_i)
        set $_count++
    end
end
document ddump
    Display $arg0 lines of hexdump for address $data_addr
end

define dd
    if ( ($arg0 & 0x40000000) || ($arg0 & 0x08000000) || ($arg0 & 0xBF000000) )
        set $data_addr=$arg0
        ddump 0x10
    else
        printf "Invalid address: %08X\n", $arg0
    end
end
document dd
    Display 16 lines of a hex dump for $arg0
end

define datawin
    if ( ($esi & 0x40000000) || ($esi & 0x08000000) || ($esi & 0xBF000000) )
        set $data_addr=$esi
    else
    if ( ($edi & 0x40000000) || ($edi & 0x08000000) || ($edi & 0xBF000000) )
        set $data_addr=$edi
    else
    if ( ($eax & 0x40000000) || ($eax & 0x08000000) || \
         ($eax & 0xBF000000) )
        set $data_addr=$eax
    else
        set $data_addr=$esp
    end
end
end
 ddump 2
end
document datawin
    Display esi, edi, eax, or esp in the data window
end

define context
    printf "_______________________________________"
    printf "________________________________________\n"
    #reg
    printf "[%04X:%08X]------------------------", $ss, $esp
    printf "---------------------------------[stack]\n"
    hexdump $sp+0x30
    hexdump $sp+0x20
    hexdump $sp+0x10
    hexdump $sp
    datawin
    printf "[%04X:%08X]------------------------", $cs, $eip
    printf "---------------------------------[ code]\n"
    x /6i $pc
    printf "---------------------------------------"
    printf "---------------------------------------\n"
end
document context
    Print regs, stack, ds:esi, and disassemble cs:eip
end

define context-on
    set $SHOW_CONTEXT = 1
end
document context-on
    Enable display of context on every program stop
end

define context-off
    set $SHOW_CONTEXT = 1
end
document context-on
    Disable display of context on every program stop
end

# Calls "context" at every breakpoint.
#define hook-stop
#  context
#end

# Init parameters
set output-radix 0x10
set input-radix 0x10
set disassembly-flavor intel


