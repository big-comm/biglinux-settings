#!/bin/bash

state="$1"
conf_dir="${NUMLOCK_SDDM_CONF_DIR:-/etc/sddm.conf.d}"
legacy_conf_file="$conf_dir/10-biglinux-numlock.conf"
conf_file="$conf_dir/99-biglinux-numlock.conf"

case "$state" in
  enable)
    value="on"
    ;;
  disable)
    value="off"
    ;;
  *)
    exit 2
    ;;
esac

install -d -m 0755 "$conf_dir" || exit $?
rm -f "$legacy_conf_file" || exit $?
{
  printf '[General]\n'
  printf 'Numlock=%s\n' "$value"
} > "$conf_file" || exit $?
chmod 0644 "$conf_file" || exit $?
