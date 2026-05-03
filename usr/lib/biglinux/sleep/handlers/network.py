"""
Network handler for sleep/resume.

Prevents WiFi PCIe devices from entering D3cold during s2idle suspend.
The Realtek rtw89 driver (RTL8852BE and similar) fails to re-initialize
after D3cold — the crystal oscillator doesn't stabilize ("xtal si not ready")
and the PCI config space becomes unreadable (header type 7f).

Strategy:
- pre_suspend: Disable d3cold_allowed for the WiFi device AND its parent
  PCIe root port.  This keeps the device in D3hot at most, preserving the
  PCIe link.  The loaded driver handles freeze/thaw during s2idle.
- post_resume: Re-enable d3cold_allowed so normal runtime PM policy applies.
  If the device ended up in a bad state anyway, fall back to module
  unload + PCI rescan + module reload.
"""
import logging
import subprocess
import time
from pathlib import Path

from .base import SleepHandler

log = logging.getLogger(__name__)

# WiFi modules known to have D3cold issues after s2idle.
_WIFI_MODULES = [
    "rtw89_8852be_git",
    "rtw89_8852be",
    "rtw89_8852ce_git",
    "rtw89_8852ce",
]

_PCI_DEVICES = Path("/sys/bus/pci/devices")
_PCI_RESCAN = Path("/sys/bus/pci/rescan")


def _find_wifi_pci() -> tuple[str, str] | None:
    """Return (module_name, pci_slot) for the first loaded rtw89 module."""
    for module in _WIFI_MODULES:
        mod_sysfs = Path(f"/sys/module/{module.replace('-', '_')}")
        if not mod_sysfs.exists():
            continue
        # Walk PCI devices looking for one bound to this driver
        try:
            for dev in _PCI_DEVICES.iterdir():
                driver_link = dev / "driver"
                if driver_link.is_symlink():
                    drv_name = driver_link.resolve().name
                    if drv_name == module.replace("-", "_") or drv_name == module:
                        return (module, dev.name)
        except OSError:
            pass
    return None


def _set_d3cold(pci_slot: str, allowed: bool) -> None:
    """Set d3cold_allowed for a PCI device and its parent bridge."""
    val = "1" if allowed else "0"
    label = "Enabled" if allowed else "Disabled"

    for target in (pci_slot, _parent_bridge(pci_slot)):
        if target is None:
            continue
        path = _PCI_DEVICES / target / "d3cold_allowed"
        try:
            path.write_text(val)
            log.info("%s d3cold for %s", label, target)
        except OSError as e:
            log.warning("Failed to set d3cold=%s for %s: %s", val, target, e)


def _parent_bridge(pci_slot: str) -> str | None:
    """Return the PCI slot of the parent bridge (e.g. '0000:00:1c.0')."""
    dev = _PCI_DEVICES / pci_slot
    try:
        real = dev.resolve()
        parent = real.parent
        # parent should be another PCI device directory
        if (parent / "d3cold_allowed").exists():
            return parent.name
    except OSError:
        pass
    return None


def _device_healthy(pci_slot: str) -> bool:
    """Return True if the PCI device config space is readable and in D0/D3hot."""
    dev = _PCI_DEVICES / pci_slot
    if not dev.exists():
        return False
    try:
        power = (dev / "power_state").read_text().strip()
        # D0 and D3hot are fine; D3cold or unknown means trouble
        return power in ("D0", "D1", "D2", "D3hot")
    except OSError:
        return False


def _fallback_recovery(module: str, pci_slot: str) -> None:
    """Aggressive recovery: unload module, PCI rescan, reload module, restart NM."""
    log.warning("WiFi device in bad state — starting fallback recovery")

    # Unload module
    try:
        subprocess.run(["modprobe", "-r", module],
                       capture_output=True, timeout=15)
        log.info("Unloaded %s for recovery", module)
    except Exception:
        pass

    time.sleep(1)

    # Remove device from PCI bus if it still exists
    remove = _PCI_DEVICES / pci_slot / "remove"
    try:
        if remove.exists():
            remove.write_text("1")
            log.info("Removed PCI device %s", pci_slot)
            time.sleep(1)
    except OSError:
        pass

    # Rescan bus
    try:
        _PCI_RESCAN.write_text("1")
        log.info("Triggered PCI bus rescan")
        time.sleep(3)
    except OSError as e:
        log.warning("PCI rescan failed: %s", e)

    # Disable d3cold again before loading (prevent immediate D3cold)
    _set_d3cold(pci_slot, False)

    # Reload module
    try:
        subprocess.run(["modprobe", module],
                       capture_output=True, timeout=30, check=True)
        log.info("Reloaded %s after recovery", module)
    except subprocess.CalledProcessError as e:
        log.error("Failed to reload %s: %s", module, e)
        return

    time.sleep(2)

    # Restart NetworkManager
    try:
        subprocess.run(["systemctl", "restart", "NetworkManager.service"],
                       capture_output=True, timeout=20)
        log.info("Restarted NetworkManager after recovery")
    except Exception as e:
        log.warning("Failed to restart NetworkManager: %s", e)


class NetworkHandler(SleepHandler):
    name = "network"

    def __init__(self) -> None:
        self._module: str | None = None
        self._pci_slot: str | None = None

    def is_available(self) -> bool:
        info = _find_wifi_pci()
        if info:
            self._module, self._pci_slot = info
            log.info("Found WiFi: module=%s pci=%s", self._module, self._pci_slot)
            return True
        return False

    def pre_suspend(self, sleep_type: str) -> None:
        if not self._pci_slot:
            return
        _set_d3cold(self._pci_slot, False)

    def post_resume(self, sleep_type: str) -> None:
        if not self._pci_slot or not self._module:
            return

        # Give the hardware a moment to stabilize after resume
        time.sleep(1)

        if _device_healthy(self._pci_slot):
            log.info("WiFi PCI device %s is healthy after resume", self._pci_slot)
            _set_d3cold(self._pci_slot, True)
        else:
            log.warning("WiFi PCI device %s unhealthy after resume", self._pci_slot)
            _fallback_recovery(self._module, self._pci_slot)
            # Re-enable d3cold for normal operation
            _set_d3cold(self._pci_slot, True)
