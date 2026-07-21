#!/bin/bash
set -euo pipefail

args=("${1:-}" battery "${2:-}")
if [[ "${3:-}" == "--critical-restore" ]]; then
  args+=(--critical-restore)
fi
exec /usr/share/biglinux/biglinux-settings/sleep/power_policy.py "${args[@]}"
