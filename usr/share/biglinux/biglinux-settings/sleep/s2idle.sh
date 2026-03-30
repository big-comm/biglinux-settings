#!/bin/bash
# s2idle.sh — Toggle s2idle (freeze) as default suspend mode via kernel cmdline.
# This prevents ASUS EC GPE storm after resuming from S3 deep sleep.

GRUB_FILE="/etc/default/grub"
PARAM="mem_sleep_default=s2idle"

if [ "$1" == "check" ]; then
    if grep -qE "GRUB_CMDLINE_LINUX_DEFAULT=.*${PARAM}" "$GRUB_FILE" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi

elif [ "$1" == "toggle" ]; then
    state="$2"
    if [ "$state" == "true" ]; then
        # Add param to GRUB_CMDLINE_LINUX_DEFAULT
        if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_FILE"; then
            sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"${PARAM} |" "$GRUB_FILE"
            # Remove any duplicates that may result
            sed -i "s|${PARAM} ${PARAM}|${PARAM}|g" "$GRUB_FILE"
        else
            echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${PARAM}\"" >> "$GRUB_FILE"
        fi
    else
        # Remove param from GRUB_CMDLINE_LINUX_DEFAULT
        sed -i "s| *${PARAM}||g" "$GRUB_FILE"
    fi

    # Regenerate GRUB config
    if command -v update-grub &>/dev/null; then
        update-grub 2>/dev/null
    elif command -v grub-mkconfig &>/dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
    fi
    exit $?
fi
