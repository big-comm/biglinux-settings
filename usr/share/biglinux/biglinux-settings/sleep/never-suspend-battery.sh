#!/bin/bash
set -euo pipefail

scriptDir="$(dirname "$(readlink -f "$0")")"
args=("${1:-}" battery "${2:-}")
if [[ "${3:-}" == "--critical-restore" ]]; then
  args+=(--critical-restore)
fi
exec "$scriptDir/power_policy.py" "${args[@]}"
