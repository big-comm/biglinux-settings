#!/bin/bash
set -euo pipefail

scriptDir="$(dirname "$(readlink -f "$0")")"
exec "$scriptDir/lid_policy.py" "${1:-}" battery "${2:-}"
