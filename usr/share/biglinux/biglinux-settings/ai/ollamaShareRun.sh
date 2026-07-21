#!/bin/bash
set -euo pipefail

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="${1:-}"
dropInDir="/etc/systemd/system/ollama.service.d"
dropInFile="${dropInDir}/90-biglinux-network.conf"

# Executes the root tasks.
case "$function" in
  install)
    install -d -m 0755 "$dropInDir"
    tmpFile="$(mktemp "${dropInDir}/.90-biglinux-network.XXXXXX")"
    trap 'rm -f "$tmpFile"' EXIT
    printf '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0"\n' > "$tmpFile"
    chmod 0644 "$tmpFile"
    mv -f "$tmpFile" "$dropInFile"
    trap - EXIT
    ;;
  uninstall)
    rm -f "$dropInFile"
    rmdir "$dropInDir" 2>/dev/null || true
    ;;
  *)
    echo "Invalid action: $function" >&2
    exit 2
    ;;
esac

systemctl daemon-reload
systemctl restart ollama.service
