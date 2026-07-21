#!/bin/bash

#Translation
export TEXTDOMAINDIR="/usr/share/locale"
export TEXTDOMAIN=biglinux-settings

# Assign the received arguments to variables with clear names
function="$1"
parameter='nowatchdog tsc=nowatchdog'

run_update_grub() {
  if [[ -e "/usr/bin/update-grub" ]];then
    /usr/bin/update-grub
  elif [[ -e "/usr/sbin/update-grub" ]];then
    /usr/sbin/update-grub
  elif [[ -e "/usr/bin/grub-mkconfig" ]];then
    /usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
  elif [[ -e "/usr/sbin/grub-mkconfig" ]];then
    /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
  elif [[ -e "/usr/bin/grub2-mkconfig" ]];then
    /usr/bin/grub2-mkconfig -o /boot/grub2/grub.cfg
  elif [[ -e "/usr/sbin/grub2-mkconfig" ]];then
    /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
  else
    return 1
  fi
}

# Executes the root tasks.
updateGrubTask() {
  if [[ "$function" == "enable" ]]; then
    if grep -q "$parameter" "/etc/default/grub"; then
      gettext "Already enabled. No changes made."
      echo
      return
    elif grep -q "GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub"; then
      # Add the parameter
      sed --follow-symlinks -i.bak -E "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s|(['\"])$| $parameter\1|" "/etc/default/grub"
    elif grep -q "GRUB_CMDLINE_LINUX=" "/etc/default/grub"; then
      # Add the parameter
      sed --follow-symlinks -i.bak -E "/^GRUB_CMDLINE_LINUX=/ s|(['\"])$| $parameter\1|" "/etc/default/grub"
    fi
  else
    # remove the parameter
    sed --follow-symlinks -i -E "s/$parameter//g" "/etc/default/grub"
  fi

  # Run update-grub only if changes were made
  # some systems do not have update-grub and grub-mkconfig in the path, so check the file directly.
  run_update_grub
}
updateGrubTask
exitCode=$?

# Exits the script with the correct exit code
exit $exitCode
