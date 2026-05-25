#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"
LIMITS_FILE="/etc/security/limits.d/99-biglinux-settings.conf"

# Executes the root tasks.
updateLimitsTask() {
  if [[ "$function" == "enable" ]]; then
    install -d -m 0755 /etc/security/limits.d
    {
      echo '@audio - rtprio 90'
      echo '@audio - memlock unlimited'
    } > "$LIMITS_FILE"
    chmod 0644 "$LIMITS_FILE"
  else
    rm -f "$LIMITS_FILE"
  fi
}
updateLimitsTask
exitCode=$?

# Exits the script with the correct exit code
exit $exitCode
