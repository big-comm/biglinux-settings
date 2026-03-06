import logging
import subprocess

logger = logging.getLogger("biglinux-settings")


class NetworkError(Exception):
    pass


class NetworkManager:
    @staticmethod
    def _run_cmd(cmd):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            logger.error("Command '%s' failed: %s", " ".join(cmd), e.stderr)
            raise NetworkError(f"Command failed: {e.stderr}") from e

    @staticmethod
    def get_interfaces():
        """Returns a list of dictionaries with interface info."""
        output = NetworkManager._run_cmd(
            ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]
        )
        interfaces = []
        for line in output.split("\n"):
            if not line:
                continue
            parts = line.split(":")
            if len(parts) >= 3:
                device = parts[0]
                type_ = parts[1]
                state = parts[2]
                connection = parts[3] if len(parts) > 3 else ""

                # Exclude loopback and bridge
                if type_ in ("loopback", "bridge"):
                    continue

                interfaces.append({
                    "device": device,
                    "type": type_,
                    "state": state,
                    "connection": connection,
                    "active": state == "connected",
                })
        return interfaces

    @staticmethod
    def connect_device(device):
        """Connects a device (enables it)."""
        NetworkManager._run_cmd(["nmcli", "device", "connect", device])

    @staticmethod
    def disconnect_device(device):
        """Disconnects a device (disables it temporarily)."""
        NetworkManager._run_cmd(["nmcli", "device", "disconnect", device])

    @staticmethod
    def get_connection_for_device(device):
        """Gets the active connection name for a given device."""
        try:
            output = NetworkManager._run_cmd(
                ["nmcli", "-t", "-f", "NAME,DEVICE", "connection", "show", "--active"]
            )
            for line in output.split("\n"):
                if not line:
                    continue
                parts = line.split(":")
                if len(parts) >= 2 and parts[1] == device:
                    return parts[0]
        except NetworkError:
            pass
        return None

    @staticmethod
    def set_autoconnect(connection_name, enable):
        """Sets the autoconnect property of a connection."""
        val = "yes" if enable else "no"
        NetworkManager._run_cmd(
            ["nmcli", "connection", "modify", connection_name, "connection.autoconnect", val]
        )
