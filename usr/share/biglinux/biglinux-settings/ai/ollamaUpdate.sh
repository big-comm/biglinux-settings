#!/bin/bash

# Action script: updates installed Ollama variants to the latest version
# available in the Arch repositories.

if [ "$1" == "run" ]; then
  pkexec $PWD/ai/ollamaUpdateRun.sh "$USER" "$DISPLAY" "$XAUTHORITY" "$DBUS_SESSION_BUS_ADDRESS" "$LANG" "$LANGUAGE"
  exit $?
fi
