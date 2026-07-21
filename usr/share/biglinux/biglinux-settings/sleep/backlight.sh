#!/bin/bash
set -euo pipefail
# backlight.sh — Toggle the backlight handler in biglinux-sleep.
# Saves/restores screen brightness and keyboard LEDs on suspend.

CONF="/etc/biglinux/sleep.conf"
KEY="backlight"

_require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        exec pkexec "$(readlink -f "$0")" "$@"
    fi
}

_ensure_conf() {
    if [ ! -f "$CONF" ]; then
        mkdir -p "$(dirname "$CONF")"
        printf '%s\n' '[handlers]' 'backlight=false' 'network=false' > "$CONF"
    fi

    grep -qE "^[[:space:]]*${KEY}[[:space:]]*=" "$CONF" || printf '%s=false\n' "$KEY" >> "$CONF"
}

if [ "${1:-}" == "check" ]; then
    val=$(grep -E "^[[:space:]]*${KEY}[[:space:]]*=" "$CONF" 2>/dev/null | tail -1 | cut -d= -f2 | tr -d ' ' || true)
    if [ "$val" == "true" ]; then
        echo "true"
    else
        echo "false"
    fi

elif [ "${1:-}" == "toggle" ]; then
    _require_root "$@"
    _ensure_conf
    state="${2:-}"
    [[ "$state" == "true" || "$state" == "false" ]] || exit 2
    temporary="$(mktemp "$(dirname "$CONF")/.sleep.conf.XXXXXX")"
    trap 'rm -f "$temporary"' EXIT
    sed "s|^[[:space:]]*${KEY}[[:space:]]*=.*|${KEY}=${state}|" "$CONF" > "$temporary"
    chmod --reference="$CONF" "$temporary"
    mv -f "$temporary" "$CONF"
    trap - EXIT
else
    exit 2
fi
