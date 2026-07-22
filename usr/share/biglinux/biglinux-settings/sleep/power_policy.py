#!/usr/bin/python3
"""Manage desktop idle-suspend policy while preserving previous values."""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

CONFIG_DIR = (
    Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    / "biglinux-settings"
    / "power-policy"
)
MISSING = "__BIGLINUX_MISSING__"
CRITICAL_POLICY_FILE = Path(
    "/etc/UPower/UPower.conf.d/90-biglinux-suspend-at-20.conf"
)


def run(command: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=check, capture_output=True, text=True)


def desktop() -> str:
    value = os.environ.get("XDG_CURRENT_DESKTOP", "").lower()
    if "cinnamon" in value:
        return "cinnamon"
    if "gnome" in value:
        return "gnome"
    if "kde" in value or "plasma" in value:
        return "kde"
    if "xfce" in value:
        return "xfce"
    return "unknown"


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


def gsettings_schema() -> str | None:
    if not command_exists("gsettings"):
        return None
    schemas = set(run(["gsettings", "list-schemas"]).stdout.splitlines())
    candidates = {
        "cinnamon": "org.cinnamon.settings-daemon.plugins.power",
        "gnome": "org.gnome.settings-daemon.plugins.power",
    }
    preferred = candidates.get(desktop())
    if preferred in schemas:
        return preferred
    for schema in candidates.values():
        if schema in schemas:
            return schema
    return None


def backend() -> str | None:
    current = desktop()
    if current == "kde" and command_exists("kwriteconfig6") and command_exists("kreadconfig6"):
        return "kde"
    if current == "xfce" and command_exists("xfconf-query"):
        return "xfce"
    if gsettings_schema():
        return "gsettings"
    return None


def gsettings_keys(source: str) -> list[tuple[str, str]]:
    schema = gsettings_schema()
    if not schema:
        return []
    available = set(run(["gsettings", "list-keys", schema]).stdout.splitlines())
    names = [f"sleep-inactive-{source}-type", f"sleep-inactive-{source}-timeout"]
    return [(schema, name) for name in names if name in available]


def kde_keys(source: str) -> list[dict[str, object]]:
    profiles = ["AC"] if source == "ac" else ["Battery", "LowBattery"]
    items = []
    for profile in profiles:
        items.extend(
            [
                {
                    "file": "powerdevilrc",
                    "groups": [profile, "SuspendAndShutdown"],
                    "key": "AutoSuspendAction",
                    "value": "0",
                },
                {
                    "file": "powermanagementprofilesrc",
                    "groups": [profile, "SuspendSession"],
                    "key": "suspendType",
                    "value": "0",
                },
            ]
        )
    return items


def xfce_key(source: str) -> str:
    return f"/xfce4-power-manager/inactivity-on-{'ac' if source == 'ac' else 'battery'}"


def kconfig_command(tool: str, item: dict[str, object]) -> list[str]:
    command = [tool, "--file", str(item["file"])]
    for group in item["groups"]:
        command.extend(["--group", str(group)])
    command.extend(["--key", str(item["key"])])
    return command


def read_values(selected: str, source: str) -> list[dict[str, object]]:
    values: list[dict[str, object]] = []
    if selected == "gsettings":
        for schema, key in gsettings_keys(source):
            value = run(["gsettings", "get", schema, key]).stdout.strip()
            values.append({"schema": schema, "key": key, "value": value})
    elif selected == "kde":
        for item in kde_keys(source):
            command = kconfig_command("kreadconfig6", item)
            command.extend(["--default", MISSING])
            value = run(command).stdout.strip()
            values.append({**item, "old_value": value})
    elif selected == "xfce":
        key = xfce_key(source)
        result = run(["xfconf-query", "-c", "xfce4-power-manager", "-p", key], check=False)
        value = result.stdout.strip() if result.returncode == 0 else MISSING
        values.append({"key": key, "old_value": value})
    return values


def backup_path(source: str, selected: str) -> Path:
    return CONFIG_DIR / f"{source}-{selected}.json"


def critical_policy_active() -> bool:
    try:
        content = CRITICAL_POLICY_FILE.read_text()
    except OSError:
        return False
    return all(
        value in content
        for value in (
            "PercentageAction=20",
            "CriticalPowerAction=Suspend",
            "AllowRiskyCriticalPowerAction=true",
        )
    )


def write_backup(source: str, selected: str, values: list[dict[str, object]]) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    backup = backup_path(source, selected)
    if backup.exists():
        return
    temporary = backup.with_suffix(".tmp")
    temporary.write_text(json.dumps({"backend": selected, "values": values}, indent=2))
    temporary.replace(backup)


def set_never(selected: str, source: str) -> None:
    if selected == "gsettings":
        for schema, key in gsettings_keys(source):
            value = "nothing" if key.endswith("-type") else "0"
            run(["gsettings", "set", schema, key, value])
    elif selected == "kde":
        for item in kde_keys(source):
            run(kconfig_command("kwriteconfig6", item) + [str(item["value"])])
        refresh_kde()
    elif selected == "xfce":
        key = xfce_key(source)
        current = run(["xfconf-query", "-c", "xfce4-power-manager", "-p", key], check=False)
        command = ["xfconf-query", "-c", "xfce4-power-manager", "-p", key]
        if current.returncode != 0:
            command.extend(["-n", "-t", "uint"])
        run(command + ["-s", "0"])


def reset_values(selected: str, source: str) -> None:
    if selected == "gsettings":
        for schema, key in gsettings_keys(source):
            run(["gsettings", "reset", schema, key])
    elif selected == "kde":
        for item in kde_keys(source):
            run(kconfig_command("kwriteconfig6", item) + ["--delete", ""])
        refresh_kde()
    elif selected == "xfce":
        run(
            ["xfconf-query", "-c", "xfce4-power-manager", "-p", xfce_key(source), "-r"],
            check=False,
        )


def restore(source: str, selected: str) -> None:
    backup = backup_path(source, selected)
    if not backup.exists():
        reset_values(selected, source)
        return
    data = json.loads(backup.read_text())
    for item in data.get("values", []):
        if selected == "gsettings":
            run(["gsettings", "set", item["schema"], item["key"], item["value"]])
        elif selected == "kde":
            command = kconfig_command("kwriteconfig6", item)
            if item["old_value"] == MISSING:
                run(command + ["--delete", ""])
            else:
                run(command + [str(item["old_value"])])
        elif selected == "xfce":
            command = ["xfconf-query", "-c", "xfce4-power-manager", "-p", item["key"]]
            if item["old_value"] == MISSING:
                run(command + ["-r"], check=False)
            else:
                run(command + ["-s", str(item["old_value"])])
    if selected == "kde":
        refresh_kde()
    backup.unlink()


def refresh_kde() -> None:
    if not command_exists("qdbus6"):
        return
    base = [
        "qdbus6",
        "org.kde.Solid.PowerManagement",
        "/org/kde/Solid/PowerManagement",
    ]
    run(base + ["org.kde.Solid.PowerManagement.reparseConfiguration"], check=False)
    run(base + ["org.kde.Solid.PowerManagement.refreshStatus"], check=False)


def is_never(selected: str, source: str) -> bool:
    if selected == "gsettings":
        values = read_values(selected, source)
        def matches(item: dict[str, object]) -> bool:
            value = str(item["value"])
            if str(item["key"]).endswith("-type"):
                return value.strip("'\"") == "nothing"
            return value in {"0", "uint32 0"}

        return bool(values) and all(matches(item) for item in values)
    if selected == "kde":
        values = read_values(selected, source)
        return bool(values) and all(item["old_value"] == "0" for item in values)
    if selected == "xfce":
        return read_values(selected, source)[0]["old_value"] == "0"
    return False


def main() -> int:
    if len(sys.argv) < 3 or sys.argv[1] not in {"check", "toggle"} or sys.argv[2] not in {"ac", "battery"}:
        return 2
    action, source = sys.argv[1:3]
    selected = backend()
    if not selected:
        print("unsupported")
        return 0 if action == "check" else 1
    if action == "check":
        print("true" if is_never(selected, source) else "false")
        return 0
    if len(sys.argv) < 4 or sys.argv[3] not in {"true", "false"}:
        return 2
    state = sys.argv[3] == "true"
    internal_restore = len(sys.argv) > 4 and sys.argv[4] == "--critical-restore"
    if source == "battery" and not state and critical_policy_active() and not internal_restore:
        print("The 20% battery policy requires idle suspend to remain disabled", file=sys.stderr)
        return 1
    if state:
        write_backup(source, selected, read_values(selected, source))
        set_never(selected, source)
    else:
        restore(source, selected)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
