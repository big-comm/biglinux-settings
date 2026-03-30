"""
biglinux-sleep-monitor — user-level D-Bus monitor for suspend/resume events.

Runs as a systemd user service. Watches for extensions that enter ERROR state
after suspend/resume and fixes them with a disable+wait+enable cycle.

With s2idle (freeze), the GNOME Shell process is simply frozen/thawed, so
extensions keep their state. No proactive disable/enable is needed.
The original user-theme corruption only happened with S3 deep sleep where
GNOME Shell went through a full extension lifecycle during resume.

This monitor is now a safety-net: it only intervenes if something goes wrong.
"""
import logging
import os
import subprocess
import sys
import time
from pathlib import Path

import gi
gi.require_version('GLib', '2.0')
gi.require_version('Gio', '2.0')
from gi.repository import GLib, Gio

sys.path.insert(0, "/usr/lib/biglinux")
from sleep.handlers.gnome import (
    _enable_extension, _disable_extension,
    _ext_state, _dbus_call,
    DEFERRED_EXTENSIONS,
)

logging.basicConfig(
    level=logging.INFO,
    format="biglinux-sleep-monitor: %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("monitor")

UID = str(os.getuid())
_just_resumed = False

# How long to wait after unlock before checking extension health (ms).
_CHECK_DELAY_MS = 2000


def _ext_op(method: str, uuid: str) -> bool:
    result = _dbus_call(UID, "org.gnome.Shell.Extensions", method, "s", uuid)
    return result == "b true"


def _disable_wait_enable(uuid: str, wait: float = 3.0) -> bool:
    """Fix an extension in ERROR state with a clean disable+wait+enable cycle."""
    log.info("Fixing %s: disable + %.1fs wait + enable", uuid, wait)
    if _ext_op("DisableExtension", uuid):
        time.sleep(wait)
        if _ext_op("EnableExtension", uuid):
            log.info("Fixed %s", uuid)
            return True
        log.warning("Could not re-enable %s", uuid)
    else:
        log.warning("Could not disable %s", uuid)
    return False


def _check_extensions_health() -> bool:
    """Check if any deferred extension is in ERROR state and fix it."""
    fixed_any = False
    for uuid in DEFERRED_EXTENSIONS:
        info = _ext_state(UID, uuid)
        if not info:
            continue
        error = info.get("error", "")
        state = info.get("state")
        if error or state == 3:  # state 3 = ERROR
            log.warning("Extension %s in bad state (state=%s, error=%s)",
                        uuid, state, error)
            if _disable_wait_enable(uuid):
                fixed_any = True
    if not fixed_any:
        log.info("All deferred extensions healthy after resume")
    return GLib.SOURCE_REMOVE


def _on_prepare_for_sleep(connection, sender, path, iface, signal, params, _):
    global _just_resumed
    going_to_sleep = params[0]

    if going_to_sleep:
        log.info("PrepareForSleep(True): system going to sleep")
        # With s2idle, no extension handling needed before suspend.
        # Extensions keep their state across freeze/thaw.
    else:
        log.info("PrepareForSleep(False): system waking up")
        _just_resumed = True
        # Schedule a health check after things settle
        GLib.timeout_add(3000, _check_extensions_health)


def _on_screensaver_changed(connection, sender, path, iface, signal, params, _):
    global _just_resumed
    is_active = params[0]

    if not is_active and _just_resumed:
        log.info("Screen unlocked after resume — checking extension health")
        _just_resumed = False
        GLib.timeout_add(_CHECK_DELAY_MS, _check_extensions_health)


def _is_gnome_session() -> bool:
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    session = os.environ.get("XDG_SESSION_DESKTOP", "")
    return "GNOME" in desktop.upper() or "gnome" in session.lower()


def main():
    if not _is_gnome_session():
        log.info("Not a GNOME session (XDG_CURRENT_DESKTOP=%s), exiting",
                 os.environ.get("XDG_CURRENT_DESKTOP", "(unset)"))
        return 0

    log.info("Starting biglinux-sleep-monitor (uid=%s)", UID)

    try:
        system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        system_bus.signal_subscribe(
            "org.freedesktop.login1",
            "org.freedesktop.login1.Manager",
            "PrepareForSleep",
            "/org/freedesktop/login1",
            None,
            Gio.DBusSignalFlags.NONE,
            _on_prepare_for_sleep,
            None,
        )
        log.info("Subscribed to PrepareForSleep on system bus")
    except GLib.Error as e:
        log.error("Cannot connect to system bus: %s", e)
        return 1

    try:
        session_bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        session_bus.signal_subscribe(
            "org.gnome.ScreenSaver",
            "org.gnome.ScreenSaver",
            "ActiveChanged",
            "/org/gnome/ScreenSaver",
            None,
            Gio.DBusSignalFlags.NONE,
            _on_screensaver_changed,
            None,
        )
        log.info("Subscribed to ScreenSaver.ActiveChanged on session bus")
    except GLib.Error as e:
        log.error("Cannot connect to session bus: %s", e)
        return 1

    # Check health at startup (in case of crash recovery)
    GLib.timeout_add(5000, _check_extensions_health)

    loop = GLib.MainLoop()
    log.info("Event loop running")
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
