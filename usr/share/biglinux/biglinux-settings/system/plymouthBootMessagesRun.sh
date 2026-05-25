#!/bin/bash

state="$1"
configDir="/etc/biglinux"
configFile="$configDir/plymouth-community.conf"
themeScript="/usr/share/plymouth/themes/community/animated-boot.script"

_remove_missing_initcpio_hook() {
  local missing_hook="$1"
  local conf="/etc/mkinitcpio.conf"
  local hooks_line hooks hook_item found new_hooks

  if [ ! -f "$conf" ]; then
    return 0
  fi

  if [ -e "/usr/lib/initcpio/hooks/$missing_hook" ] || [ -e "/usr/lib/initcpio/install/$missing_hook" ]; then
    return 0
  fi

  hooks_line="$(grep -E '^[[:space:]]*HOOKS=\(' "$conf" | tail -n1)"
  if [ -z "$hooks_line" ]; then
    return 0
  fi

  hooks="${hooks_line#*\(}"
  hooks="${hooks%\)*}"
  found=0
  new_hooks=()

  for hook_item in $hooks; do
    if [ "$hook_item" = "$missing_hook" ]; then
      found=1
      continue
    fi
    new_hooks+=("$hook_item")
  done

  if [ "$found" -eq 0 ]; then
    return 0
  fi

  cp -a -- "$conf" "${conf}.biglinux-settings.bak"
  sed --follow-symlinks -i \
    "s|^[[:space:]]*HOOKS=.*|HOOKS=(${new_hooks[*]})|" \
    "$conf"
  printf 'Removed missing mkinitcpio hook from %s: %s\n' "$conf" "$missing_hook" >&2
}

_rebuild_initramfs() {
  if ! command -v mkinitcpio >/dev/null 2>&1; then
    return 0
  fi

  local preset preset_name kver attempted built failed
  attempted=0
  built=0
  failed=0

  shopt -s nullglob
  for preset in /etc/mkinitcpio.d/*.preset; do
    preset_name="$(basename "$preset" .preset)"
    kver="$(
      unset ALL_kver default_kver
      . "$preset" 2>/dev/null
      printf '%s' "${default_kver:-$ALL_kver}"
    )"

    if [ -n "$kver" ] && [ ! -r "$kver" ]; then
      printf 'Skipping mkinitcpio preset %s: kernel image is not readable: %s\n' "$preset_name" "$kver" >&2
      continue
    fi

    attempted=$((attempted + 1))
    if mkinitcpio -p "$preset_name"; then
      built=1
    else
      failed=1
    fi
  done
  shopt -u nullglob

  if [ "$attempted" -eq 0 ]; then
    mkinitcpio -P
    return $?
  fi

  if [ "$built" -eq 1 ]; then
    if [ "$failed" -eq 1 ]; then
      printf 'WARNING: Some mkinitcpio presets failed, but at least one image was rebuilt.\n' >&2
    fi
    return 0
  fi

  return 1
}

if [ "$state" != "true" ] && [ "$state" != "false" ]; then
  exit 1
fi

mkdir -p "$configDir"

if [ -f "$configFile" ]; then
  if grep -qE '^[[:space:]]*SHOW_BOOT_MESSAGES[[:space:]]*=' "$configFile"; then
    sed -i "s/^[[:space:]]*SHOW_BOOT_MESSAGES[[:space:]]*=.*/SHOW_BOOT_MESSAGES=$state/" "$configFile"
  else
    printf '\nSHOW_BOOT_MESSAGES=%s\n' "$state" >> "$configFile"
  fi
else
  {
    printf '# BigCommunity Plymouth settings\n'
    printf 'SHOW_BOOT_MESSAGES=%s\n' "$state"
  } > "$configFile"
fi

chmod 0644 "$configFile"

if [ -f "$themeScript" ]; then
  if [ "$state" == "true" ]; then
    sed -i \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetDisplayMessageFunction.*\)|\1|' \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetHideMessageFunction.*\)|\1|' \
      -e 's|^[[:space:]]*#[[:space:]]*\(Plymouth\.SetUpdateStatusFunction.*\)|\1|' \
      "$themeScript"
  else
    sed -i \
      -e 's|^[[:space:]]*\(Plymouth\.SetDisplayMessageFunction.*\)|# \1|' \
      -e 's|^[[:space:]]*\(Plymouth\.SetHideMessageFunction.*\)|# \1|' \
      -e 's|^[[:space:]]*\(Plymouth\.SetUpdateStatusFunction.*\)|# \1|' \
      "$themeScript"
  fi
fi

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  _remove_missing_initcpio_hook "bootsplash-biglinux"
  plymouth-set-default-theme community && _rebuild_initramfs
elif command -v mkinitcpio >/dev/null 2>&1; then
  _remove_missing_initcpio_hook "bootsplash-biglinux"
  _rebuild_initramfs
fi
