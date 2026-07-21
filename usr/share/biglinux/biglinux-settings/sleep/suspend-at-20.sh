#!/bin/bash
set -euo pipefail

dropInFile="/etc/UPower/UPower.conf.d/90-biglinux-suspend-at-20.conf"
configDir="${XDG_CONFIG_HOME:-$HOME/.config}/biglinux-settings/power-policy"
markerFile="$configDir/critical-20-managed-idle"
batteryPolicy="/usr/share/biglinux/biglinux-settings/sleep/never-suspend-battery.sh"
rootHelper="/usr/share/biglinux/biglinux-settings/sleep/suspend-at-20Run.sh"

is_enabled() {
  [[ -r "$dropInFile" ]] &&
    grep -Fxq 'UsePercentageForPolicy=true' "$dropInFile" &&
    grep -Fxq 'PercentageLow=25' "$dropInFile" &&
    grep -Fxq 'PercentageCritical=22' "$dropInFile" &&
    grep -Fxq 'PercentageAction=20' "$dropInFile" &&
    grep -Fxq 'CriticalPowerAction=Suspend' "$dropInFile" &&
    grep -Fxq 'AllowRiskyCriticalPowerAction=true' "$dropInFile"
}

case "${1:-}" in
  check)
    if [[ ! -x /usr/lib/upowerd && ! -x /usr/libexec/upowerd ]]; then
      echo unsupported
      exit 0
    fi
    if is_enabled && [[ "$($batteryPolicy check)" == "true" ]]; then
      echo true
    else
      echo false
    fi
    ;;
  toggle)
    [[ -x /usr/lib/upowerd || -x /usr/libexec/upowerd ]] || exit 1
    state="${2:-}"
    if [[ "$state" == "true" ]]; then
      managedIdle=false
      if [[ "$($batteryPolicy check)" != "true" ]]; then
        "$batteryPolicy" toggle true
        mkdir -p "$configDir"
        : > "$markerFile"
        managedIdle=true
      fi
      if ! pkexec "$rootHelper" enable; then
        if [[ "$managedIdle" == "true" ]]; then
          "$batteryPolicy" toggle false --critical-restore || true
          rm -f "$markerFile"
        fi
        exit 1
      fi
    elif [[ "$state" == "false" ]]; then
      pkexec "$rootHelper" disable
      if [[ -f "$markerFile" ]]; then
        "$batteryPolicy" toggle false --critical-restore
        rm -f "$markerFile"
      fi
    else
      exit 2
    fi
    ;;
  *)
    exit 2
    ;;
esac
