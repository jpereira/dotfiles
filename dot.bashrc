# Interactive Bash startup (Linux and macOS).
case $- in *i*) ;; *) return ;; esac

if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi
[ ! -f "$HOME/.bash_profile" ] || source "$HOME/.bash_profile"

# Readline owns bracketed paste; no repeated PROMPT_COMMAND hooks are necessary.
if [ "${TERM:-dumb}" != dumb ]; then
    bind 'set enable-bracketed-paste off' 2>/dev/null || true
fi
