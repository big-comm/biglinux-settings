#!/bin/bash
# lid-suspend.sh — Force suspend on lid close when on AC power.
# By default some systems only lock (or do nothing) on lid close with AC.

CONF_DIR="/etc/systemd/logind.conf.d"
CONF_FILE="${CONF_DIR}/biglinux-lid-suspend.conf"

if [ "$1" == "check" ]; then
    if [ -f "$CONF_FILE" ]; then
        echo "true"
    else
        echo "false"
    fi

elif [ "$1" == "toggle" ]; then
    state="$2"
    if [ "$state" == "true" ]; then
        mkdir -p "$CONF_DIR"
        cat > "$CONF_FILE" << 'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
        # Reload logind to apply
        systemctl kill -s HUP systemd-logind 2>/dev/null
    else
        rm -f "$CONF_FILE"
        systemctl kill -s HUP systemd-logind 2>/dev/null
    fi
    exit $?
fi
