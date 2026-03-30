#!/bin/bash
# gnome-monitor.sh — Toggle GNOME extension health monitor.
# Enables gnome handler in sleep.conf + systemd user service for monitoring.

CONF="/etc/biglinux/sleep.conf"
KEY="gnome"
SERVICE_NAME="biglinux-sleep-monitor"
SERVICE_FILE="/usr/lib/systemd/user/${SERVICE_NAME}.service"

_ensure_conf() {
    if [ ! -f "$CONF" ]; then
        mkdir -p "$(dirname "$CONF")"
        cat > "$CONF" << 'EOF'
[handlers]
backlight=false
network=false
gnome=false
EOF
    fi
}

if [ "$1" == "check" ]; then
    _ensure_conf
    val=$(grep -E "^${KEY}\s*=" "$CONF" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d ' ')
    if [ "$val" == "true" ]; then
        echo "true"
    else
        echo "false"
    fi

elif [ "$1" == "toggle" ]; then
    _ensure_conf
    state="$2"
    sed -i "s|^${KEY}\s*=.*|${KEY}=${state}|" "$CONF"

    # Also enable/disable the user-level monitor service for all logged-in users
    if [ "$state" == "true" ]; then
        # Enable the user service globally
        for uid_dir in /run/user/*/; do
            uid=$(basename "$uid_dir")
            user=$(id -nu "$uid" 2>/dev/null) || continue
            if pgrep -u "$uid" gnome-shell &>/dev/null; then
                su - "$user" -c "systemctl --user enable --now ${SERVICE_NAME}.service" 2>/dev/null &
            fi
        done
    else
        # Disable the user service for all logged-in users
        for uid_dir in /run/user/*/; do
            uid=$(basename "$uid_dir")
            user=$(id -nu "$uid" 2>/dev/null) || continue
            su - "$user" -c "systemctl --user disable --now ${SERVICE_NAME}.service" 2>/dev/null &
        done
    fi
    wait
    exit $?
fi
