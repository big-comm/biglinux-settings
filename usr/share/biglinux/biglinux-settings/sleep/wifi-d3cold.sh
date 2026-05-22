#!/bin/bash
# wifi-d3cold.sh — Toggle the network handler in biglinux-sleep.
# Prevents Realtek rtw89 WiFi d3cold power gating on suspend.

CONF="/etc/biglinux/sleep.conf"
KEY="network"

_require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        exec pkexec "$(readlink -f "$0")" "$@"
    fi
}

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

    grep -qE "^[[:space:]]*${KEY}[[:space:]]*=" "$CONF" || printf '%s=false\n' "$KEY" >> "$CONF"
}

if [ "$1" == "check" ]; then
    val=$(grep -E "^[[:space:]]*${KEY}[[:space:]]*=" "$CONF" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d ' ')
    if [ "$val" == "true" ]; then
        echo "true"
    else
        echo "false"
    fi

elif [ "$1" == "toggle" ]; then
    _require_root "$@"
    _ensure_conf
    state="$2"
    sed -i "s|^[[:space:]]*${KEY}[[:space:]]*=.*|${KEY}=${state}|" "$CONF"
    exit $?
fi
