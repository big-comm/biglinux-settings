import logging
import os
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from base_page import BaseSettingsPage, _  # noqa: E402

logger = logging.getLogger("biglinux-settings")


def _detect_desktop() -> str:
    """Return the current desktop environment id."""
    de = os.environ.get("XDG_CURRENT_DESKTOP", "").lower()
    if "gnome" in de:
        return "gnome"
    if "kde" in de or "plasma" in de:
        return "kde"
    if "cinnamon" in de:
        return "cinnamon"
    if "xfce" in de:
        return "xfce"
    return de or "unknown"


def _has_rtw89() -> bool:
    """Check if any rtw89 WiFi module is loaded."""
    try:
        out = subprocess.run(
            ["lsmod"], capture_output=True, text=True, timeout=5
        ).stdout
        return "rtw89" in out
    except Exception:
        return False


def _has_asus_ec_bug() -> bool:
    """Detect ASUS notebooks susceptible to EC GPE bug after S3 deep sleep."""
    try:
        vendor_path = "/sys/class/dmi/id/board_vendor"
        if not os.path.exists(vendor_path):
            return False
        with open(vendor_path) as f:
            vendor = f.read().strip().lower()
        if "asus" not in vendor:
            return False

        # Check if deep sleep is available (the bug only matters when S3 exists)
        mem_sleep_path = "/sys/power/mem_sleep"
        if os.path.exists(mem_sleep_path):
            with open(mem_sleep_path) as f:
                modes = f.read().strip()
            if "deep" in modes:
                return True
        return False
    except Exception:
        return False


class SleepPage(BaseSettingsPage):
    def __init__(self, main_window, **kwargs):
        super().__init__(main_window, **kwargs)

        self._desktop = _detect_desktop()

        content = self.create_scrolled_content()

        # --- Sleep mode (only for ASUS with EC bug) ---
        if _has_asus_ec_bug():
            grp_sleep = self.create_group(
                _("Sleep Mode"),
                _("Configure how the system suspends."),
                "sleep",
            )
            content.append(grp_sleep)

            self.create_row(
                grp_sleep,
                _("Use s2idle (light sleep)"),
                _(
                    "Uses a lighter sleep mode that preserves Fn keys "
                    "and device state. Recommended for ASUS notebooks."
                ),
                "s2idle",
                "sleep-symbolic",
                info_text=_(
                    "S3 deep sleep can cause the Embedded Controller to stop "
                    "generating hotkey interrupts. s2idle keeps the EC powered, "
                    "avoiding this issue at a small cost in battery consumption."
                ),
            )

        # --- WiFi d3cold prevention (only if rtw89 loaded) ---
        if _has_rtw89():
            grp_wifi = self.create_group(
                _("WiFi"),
                _("Prevent WiFi issues after suspend."),
                "sleep",
            )
            content.append(grp_wifi)

            self.create_row(
                grp_wifi,
                _("Protect WiFi on suspend"),
                _(
                    "Prevents the Realtek WiFi chip from fully powering off "
                    "(d3cold), avoiding connection loss after resume."
                ),
                "wifi-d3cold",
                "wifi-symbolic",
                info_text=_(
                    "Some Realtek RTL8852BE/CE chips fail to reinitialize "
                    "after d3cold power gating. This keeps the chip in d3hot "
                    "(PCIe link alive) during suspend."
                ),
            )

        # --- Backlight save/restore (always visible) ---
        grp_backlight = self.create_group(
            _("Display and Keyboard"),
            _("Preserve brightness and LED state across suspend."),
            "sleep",
        )
        content.append(grp_backlight)

        self.create_row(
            grp_backlight,
            _("Save/restore brightness on suspend"),
            _(
                "Saves screen brightness and keyboard LEDs before "
                "suspending and restores them on resume."
            ),
            "backlight",
            "sleep-symbolic",
        )

        # --- GNOME extension monitor (only on GNOME) ---
        if self._desktop == "gnome":
            grp_gnome = self.create_group(
                _("GNOME Shell Extensions"),
                _("Automatic health check after resume."),
                "sleep",
            )
            content.append(grp_gnome)

            self.create_row(
                grp_gnome,
                _("Extension health monitor"),
                _(
                    "Detects GNOME Shell extensions in error state after "
                    "resume and automatically restarts them."
                ),
                "gnome-monitor",
                "sleep-symbolic",
            )

        # --- Lid switch (always visible) ---
        grp_lid = self.create_group(
            _("Lid Switch"),
            _("Laptop lid close behavior."),
            "sleep",
        )
        content.append(grp_lid)

        self.create_row(
            grp_lid,
            _("Suspend on lid close (AC power)"),
            _(
                "Some systems do not suspend when on AC power. "
                "This forces suspend when the lid is closed."
            ),
            "lid-suspend",
            "sleep-symbolic",
        )
