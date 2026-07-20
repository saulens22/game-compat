#!/usr/bin/env python3
"""Safely add or update one native non-Steam shortcut."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import zlib

if sys.prefix == sys.base_prefix:
    raise SystemExit("Run this tool through ./run-python-tool.sh")

try:
    import vdf
except ImportError as exc:
    raise SystemExit("The managed Python environment is incomplete") from exc


def steam_running() -> bool:
    result = subprocess.run(
        ["pgrep", "-f", r"/(steam|steamwebhelper)( |$)"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def steam_root() -> Path:
    candidates = (
        Path.home() / ".local/share/Steam",
        Path.home() / ".steam/steam",
    )
    for candidate in candidates:
        if (candidate / "userdata").is_dir():
            return candidate.resolve()
    raise SystemExit("Steam userdata directory was not found")


def shortcut_file(root: Path, account: str | None) -> Path:
    if account:
        candidates = [root / "userdata" / account / "config/shortcuts.vdf"]
    else:
        candidates = list(root.glob("userdata/[0-9]*/config/shortcuts.vdf"))
    candidates = [path for path in candidates if path.is_file()]
    if len(candidates) != 1:
        raise SystemExit(
            f"Expected exactly one shortcuts.vdf, found {len(candidates)}; use --account ACCOUNT_ID"
        )
    return candidates[0]


def signed_app_id(executable: str, name: str) -> int:
    value = zlib.crc32((executable + name).encode("utf-8")) | 0x80000000
    return value - 0x100000000 if value >= 0x80000000 else value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    parser.add_argument("target", type=Path)
    parser.add_argument("--account")
    parser.add_argument("--yes", action="store_true", help="allow graceful Steam shutdown")
    parser.add_argument("--no-restart", action="store_true")
    args = parser.parse_args()

    target = args.target.expanduser().resolve()
    if not target.is_file() or not os.access(target, os.X_OK):
        raise SystemExit(f"Shortcut target is missing or not executable: {target}")
    path = shortcut_file(steam_root(), args.account)

    was_running = steam_running()
    if was_running:
        print("WARNING: Steam must close before shortcuts.vdf can be edited safely.", file=sys.stderr)
        if not args.yes:
            answer = input("Close Steam gracefully and continue? [y/N] ")
            if answer.lower() != "y":
                return 0
        subprocess.run(["steam", "-shutdown"], check=False)
        for _ in range(60):
            if not steam_running():
                break
            time.sleep(0.5)
        else:
            raise SystemExit("Steam did not exit; shortcut database was not changed")

    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup_dir = Path(__file__).resolve().parent / "_work/steam-shortcut-backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup = backup_dir / f"shortcuts-{stamp}.vdf"
    shutil.copy2(path, backup)

    with path.open("rb") as stream:
        data = vdf.binary_load(stream)
    shortcuts = data.setdefault("shortcuts", {})
    quoted_target = f'"{target}"'
    quoted_start = f'"{target.parent}"'
    existing_key = next(
        (key for key, item in shortcuts.items() if item.get("AppName") == args.name),
        str(len(shortcuts)),
    )
    shortcuts[existing_key] = {
        "appid": signed_app_id(quoted_target, args.name),
        "AppName": args.name,
        "Exe": quoted_target,
        "StartDir": quoted_start,
        "icon": "",
        "ShortcutPath": "",
        "LaunchOptions": "",
        "IsHidden": 0,
        "AllowDesktopConfig": 1,
        "AllowOverlay": 1,
        "OpenVR": 0,
        "Devkit": 0,
        "DevkitGameID": "",
        "DevkitOverrideAppID": 0,
        "LastPlayTime": 0,
        "FlatpakAppID": "",
        "tags": {},
    }
    temporary = path.with_suffix(".vdf.tmp")
    with temporary.open("wb") as stream:
        vdf.binary_dump(data, stream)
    with temporary.open("rb") as stream:
        checked = vdf.binary_load(stream)
    if checked["shortcuts"][existing_key]["Exe"] != quoted_target:
        temporary.unlink(missing_ok=True)
        raise SystemExit("Shortcut verification failed; original database was not replaced")
    os.replace(temporary, path)
    print(f"Steam shortcut ready: {args.name}")
    print(f"Backup: {backup}")

    if was_running and not args.no_restart:
        subprocess.Popen(
            ["steam", "-silent"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
