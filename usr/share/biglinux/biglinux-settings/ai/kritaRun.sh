#!/bin/bash
set -euo pipefail

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="${1:-}"

# Executes the root tasks.
if [[ "$function" != "install" ]]; then
  echo "Invalid action: $function" >&2
  exit 2
fi
pacman -Syu --needed --noconfirm krita p7zip
