#!/bin/bash
set -euo pipefail

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="${1:-}"

# Executes the root tasks.
case "$function" in
  install)
    pacman -Syu --needed --noconfirm biglinux-docker-config
    systemctl enable --now docker.service docker.socket
    ;;
  enable)
    systemctl enable --now docker.service docker.socket
    ;;
  disable)
    systemctl disable --now docker.service docker.socket
    ;;
  *)
    echo "Invalid action: $function" >&2
    exit 2
    ;;
esac
