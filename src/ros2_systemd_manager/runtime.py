import os
import subprocess
import sys
from typing import List


def log(message: str) -> None:
    """Unified info output for readable execution progress."""
    print(f"[INFO] {message}")


def err(message: str) -> None:
    """Unified error output."""
    print(f"[ERROR] {message}", file=sys.stderr)


def run_cmd(cmd: List[str]) -> None:
    """Run a system command and raise on failure."""
    subprocess.run(cmd, check=True)


def require_root() -> None:
    """Root privileges are required for /etc/systemd/system and systemctl operations."""
    if os.geteuid() != 0:
        err("Please run this script with sudo/root privileges.")
        sys.exit(1)
