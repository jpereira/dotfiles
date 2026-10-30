# Invalidate cached sudo credentials and clear Linux virtual consoles on logout.
if [ -x /usr/bin/sudo ]; then
    /usr/bin/sudo -K
fi
if [ "$SHLVL" = 1 ] && [ -x /usr/bin/clear_console ]; then
    /usr/bin/clear_console -q
fi
