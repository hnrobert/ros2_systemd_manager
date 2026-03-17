#!/usr/bin/env python3
"""Compatibility launcher for local usage from repository root."""

import sys
from pathlib import Path


def _bootstrap_src_path() -> None:
    repo_root = Path(__file__).resolve().parent
    src_path = repo_root / "src"
    src_str = str(src_path)
    if src_path.exists() and src_str not in sys.path:
        sys.path.insert(0, src_str)


def main() -> int:
    _bootstrap_src_path()
    from ros2_systemd_manager.cli import entrypoint

    return entrypoint()


if __name__ == "__main__":
    raise SystemExit(main())
