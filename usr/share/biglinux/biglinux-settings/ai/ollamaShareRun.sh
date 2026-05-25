#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"

# Executes the root tasks.
updateTask() {
  if [[ "$function" == "install" ]]; then
    sed -i /'WorkingDirectory=/{p;s/.*/Environment="OLLAMA_HOST=0.0.0.0"/;}' /usr/lib/systemd/system/ollama.service
    systemctl daemon-reload
    systemctl restart ollama.service
  else
    sed -i '/Environment="OLLAMA_HOST=0.0.0.0"/d' /usr/lib/systemd/system/ollama.service
    systemctl daemon-reload
    systemctl restart ollama.service
  fi
  exitCode=$?
}
updateTask

# Exits the script with the correct exit code
exit $exitCode
