#!/bin/bash
set -euo pipefail

exec /usr/share/biglinux/biglinux-settings/sleep/power_policy.py "${1:-}" ac "${2:-}"
