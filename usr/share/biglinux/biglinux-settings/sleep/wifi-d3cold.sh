#!/bin/bash
# wifi-d3cold.sh — Toggle the network handler in biglinux-sleep.
# Prevents Realtek rtw89 WiFi d3cold power gating on suspend.

CONF="/etc/biglinux/sleep.conf"
KEY="network"

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
    exit $?
fi
