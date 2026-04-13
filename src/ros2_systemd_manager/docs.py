"""Load and display bundled documentation for CPU isolation setup."""

from __future__ import annotations

import re
from importlib import resources
from pathlib import Path

from .runtime import err


def _load_cpu_isolation_doc() -> str:
    """Load CPU_isolation.md from package data, with repo fallback."""
    packaged = resources.files("ros2_systemd_manager").joinpath(
        "docs/CPU_isolation.md"
    )
    if packaged.is_file():
        return packaged.read_text(encoding="utf-8")

    # Fallback: repo root / docs / ...
    repo_candidate = Path(__file__).resolve().parents[2] / "docs" / "CPU_isolation.md"
    if repo_candidate.exists():
        return repo_candidate.read_text(encoding="utf-8")

    err(
        "CPU isolation document not found. "
        "Expected docs/CPU_isolation.md to be bundled."
    )
    raise SystemExit(1)


def _strip_image_lines(text: str) -> str:
    """Remove Markdown image lines that are not useful in a terminal."""
    lines = text.splitlines()
    filtered: list[str] = []
    for line in lines:
        # Match ![alt](path)
        if re.match(r"^\s*!\[.*?\]\(.*?\)\s*$", line):
            continue
        # Match <img ...> HTML tags
        if re.match(r"^\s*<img\s", line):
            continue
        filtered.append(line)
    return "\n".join(filtered)


def show_cpu_isolation_doc() -> None:
    """Print the CPU isolation setup guide to the terminal."""
    raw = _load_cpu_isolation_doc()
    cleaned = _strip_image_lines(raw)
    print(cleaned)
