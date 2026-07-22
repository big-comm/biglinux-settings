"""Tests for lid-close policy persistence and desktop integration."""

import importlib.util
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "usr/share/biglinux/biglinux-settings/sleep/lid_policy.py"


@pytest.fixture
def policy_module(tmp_path, monkeypatch):
    spec = importlib.util.spec_from_file_location("lid_policy", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    monkeypatch.setattr(module, "CONFIG_DIR", tmp_path / "config")
    return module


def test_kde_battery_policy_covers_regular_and_low_battery_profiles(policy_module):
    items = policy_module.kde_items("battery")

    assert {item["groups"][0] for item in items} == {"Battery", "LowBattery"}
    assert all(item["value"] == "0" for item in items)
    assert {item["key"] for item in items} == {"LidAction", "lidAction"}


def test_xfce_policy_restores_previous_lid_action(policy_module, monkeypatch):
    key = "/xfce4-power-manager/lid-action-on-battery"
    values = {key: "1"}

    def fake_run(command, check=True):
        selected_key = command[command.index("-p") + 1]
        if "-s" in command:
            values[selected_key] = command[-1]
            return subprocess.CompletedProcess(command, 0, "", "")
        if "-r" in command:
            values.pop(selected_key, None)
            return subprocess.CompletedProcess(command, 0, "", "")
        if selected_key not in values:
            return subprocess.CompletedProcess(command, 1, "", "missing")
        return subprocess.CompletedProcess(command, 0, values[selected_key] + "\n", "")

    monkeypatch.setattr(policy_module, "run", fake_run)
    saved = policy_module.read_values("xfce", "battery")
    policy_module.write_backup("battery", "xfce", saved)
    policy_module.set_never("xfce", "battery")

    assert values[key] == "4"
    assert policy_module.native_is_never("xfce", "battery")
    policy_module.restore_all("battery")
    assert values[key] == "1"


def test_enable_rolls_back_desktop_policy_when_system_policy_fails(
    policy_module, monkeypatch
):
    events = []
    monkeypatch.setattr(policy_module, "backend", lambda _source: "kde")
    monkeypatch.setattr(policy_module, "read_values", lambda *_args: [])
    monkeypatch.setattr(
        policy_module, "write_backup", lambda *_args: events.append("backup")
    )
    monkeypatch.setattr(policy_module, "set_never", lambda *_args: events.append("set"))
    monkeypatch.setattr(
        policy_module, "restore_all", lambda *_args: events.append("restore")
    )
    monkeypatch.setattr(
        policy_module,
        "run",
        lambda command, check=False: subprocess.CompletedProcess(
            command, 1, "", "failed"
        ),
    )
    monkeypatch.setattr(
        policy_module.sys,
        "argv",
        ["lid_policy.py", "toggle", "ac", "true"],
    )

    assert policy_module.main() == 1
    assert events == ["backup", "set", "restore"]


def test_enable_rolls_back_partially_applied_desktop_policy(policy_module, monkeypatch):
    events = []
    monkeypatch.setattr(policy_module, "backend", lambda _source: "kde")
    monkeypatch.setattr(policy_module, "read_values", lambda *_args: [])
    monkeypatch.setattr(
        policy_module, "write_backup", lambda *_args: events.append("backup")
    )
    monkeypatch.setattr(
        policy_module,
        "set_never",
        lambda *_args: (_ for _ in ()).throw(subprocess.CalledProcessError(1, "write")),
    )
    monkeypatch.setattr(
        policy_module, "restore_all", lambda *_args: events.append("restore")
    )
    monkeypatch.setattr(
        policy_module.sys,
        "argv",
        ["lid_policy.py", "toggle", "ac", "true"],
    )

    assert policy_module.main() == 1
    assert events == ["backup", "restore"]


def test_lid_policy_does_not_disable_explicit_suspend_requests():
    root_content = (MODULE_PATH.with_name("lid-policy-root.sh")).read_text(
        encoding="utf-8"
    )
    user_content = MODULE_PATH.read_text(encoding="utf-8")

    assert "HandleLidSwitch=ignore" in root_content
    assert "HandleLidSwitchExternalPower=ignore" in root_content
    assert "IgnoreLid" not in root_content
    assert "sleep.target" not in root_content
    assert "suspend.target" not in root_content
    assert "systemd-inhibit" not in root_content
    assert "org.gnome.desktop.screensaver" not in user_content


def test_lid_policy_uses_reload_and_effective_state_verification():
    content = (MODULE_PATH.with_name("lid-policy-root.sh")).read_text(encoding="utf-8")

    assert "--signal=HUP" in content
    assert "systemctl restart" not in content
    assert "busctl get-property" in content
    assert "biglinux-lid-suspend.conf" in content
    assert "flock 9" in content
