#!/usr/bin/env python3
"""Validate the portable, publishable structure of this repository."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CASE_FILES = {"README.md", "RESULTS.md", "requirements.txt", "upstream.json", "versions.json"}
CASE_SECTIONS = (
    "## Tested with",
    "## Default behavior",
    "## Final behavior",
    "## Fixes required to reach it",
    "## Quick commands",
    "## Steam launch options",
    "## Notes for research",
    "## TODO (not yet fixed)",
)
STEAM_NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*-[0-9]+$")
SLUG = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*$")
PRIVATE_PATHS = re.compile(r"(^|/)(_work|configs|runtime|tool-downloads)(/|$)|(^|/)(logs|evidence)/.+")
ABSOLUTE_USER_PATH = re.compile(r"/(?:home|Users)/[^/\s]+/")


def tracked_files() -> list[Path]:
    output = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
    )
    return [path for item in output.split(b"\0") if item if (path := ROOT / item.decode()).is_file()]


def validate_case(case: Path, errors: list[str]) -> None:
    relative = case.relative_to(ROOT)
    missing = sorted(name for name in CASE_FILES if not (case / name).is_file())
    if missing:
        errors.append(f"{relative}: missing required files: {', '.join(missing)}")

    readme = case / "README.md"
    if readme.is_file():
        text = readme.read_text(encoding="utf-8")
        positions = [text.find(section) for section in CASE_SECTIONS]
        absent = [section for section, position in zip(CASE_SECTIONS, positions) if position < 0]
        if absent:
            errors.append(f"{relative}/README.md: missing sections: {', '.join(absent)}")
        elif positions != sorted(positions):
            errors.append(f"{relative}/README.md: standard sections are out of order")

    upstream = case / "upstream.json"
    if upstream.is_file():
        try:
            entries = json.loads(upstream.read_text(encoding="utf-8"))
            if not isinstance(entries, list):
                raise ValueError("top level must be a list")
            for index, entry in enumerate(entries):
                if not isinstance(entry, dict) or set(entry) != {"name", "url"}:
                    raise ValueError(f"entry {index} must contain only name and url")
                if not all(isinstance(entry[key], str) and entry[key].strip() for key in ("name", "url")):
                    raise ValueError(f"entry {index} has an empty or non-string value")
                if not entry["url"].startswith("https://"):
                    raise ValueError(f"entry {index} URL must use https")
        except (json.JSONDecodeError, ValueError) as exc:
            errors.append(f"{relative}/upstream.json: {exc}")

    versions_file = case / "versions.json"
    if versions_file.is_file():
        try:
            versions = json.loads(versions_file.read_text(encoding="utf-8"))
            if set(versions) != {"current", "history"}:
                raise ValueError("must contain only current and history")
            if not isinstance(versions["current"], str) or not re.fullmatch(r"v[1-9][0-9]*", versions["current"]):
                raise ValueError("current must look like v1")
            if not isinstance(versions["history"], list) or not versions["history"]:
                raise ValueError("history must be a non-empty list")
            names = []
            for index, item in enumerate(versions["history"]):
                if not isinstance(item, dict) or set(item) != {"version", "summary"}:
                    raise ValueError(f"history entry {index} must contain version and summary")
                if not all(isinstance(item[key], str) and item[key].strip() for key in item):
                    raise ValueError(f"history entry {index} contains an empty value")
                names.append(item["version"])
            if len(names) != len(set(names)) or versions["current"] not in names:
                raise ValueError("history versions must be unique and include current")
        except (json.JSONDecodeError, ValueError) as exc:
            errors.append(f"{relative}/versions.json: {exc}")


def main() -> int:
    errors: list[str] = []
    tracked = tracked_files()

    for path in tracked:
        relative = path.relative_to(ROOT)
        value = relative.as_posix()
        allowed_index = relative.name == "README.md" and relative.parent.name in {"evidence", "logs"}
        if PRIVATE_PATHS.search(value) and not allowed_index:
            errors.append(f"{value}: generated or private path must not be tracked")
        if relative.suffix in {".md", ".sh", ".py", ".yml", ".yaml", ".json", ".txt"}:
            text = path.read_text(encoding="utf-8")
            if ABSOLUTE_USER_PATH.search(text):
                errors.append(f"{value}: contains a user-specific absolute path")

    shell_files = [path for path in tracked if path.suffix == ".sh"]
    for script in shell_files:
        result = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
        if result.returncode:
            errors.append(f"{script.relative_to(ROOT)}: bash -n failed: {result.stderr.strip()}")

    python_files = [path for path in tracked if path.suffix == ".py"]
    for script in python_files:
        try:
            compile(script.read_text(encoding="utf-8"), str(script), "exec")
        except SyntaxError as exc:
            errors.append(f"{script.relative_to(ROOT)}: Python syntax error: {exc}")

    cases: list[Path] = []
    for child in (ROOT / "steam").iterdir():
        if child.is_dir():
            if not STEAM_NAME.fullmatch(child.name):
                errors.append(f"steam/{child.name}: expected <game-slug>-<numeric-app-id>")
            if any((child / name).is_file() for name in CASE_FILES):
                cases.append(child)

    for child in (ROOT / "windows").iterdir():
        if child.is_dir():
            if not SLUG.fullmatch(child.name):
                errors.append(f"windows/{child.name}: expected a lowercase game slug")
            if any((child / name).is_file() for name in CASE_FILES):
                cases.append(child)

    for system in (ROOT / "emulators").iterdir():
        if not system.is_dir():
            continue
        if system.name == "frontends":
            for frontend in system.iterdir():
                if frontend.is_dir():
                    if not SLUG.fullmatch(frontend.name):
                        errors.append(f"emulators/frontends/{frontend.name}: expected a lowercase frontend slug")
                    cases.append(frontend)
            continue
        if not SLUG.fullmatch(system.name):
            errors.append(f"emulators/{system.name}: expected a lowercase system slug")
        if (system / "RESULTS.md").is_file() and (system / "requirements.txt").is_file():
            cases.append(system)
        for child in system.iterdir():
            if child.is_dir() and not child.name.startswith("."):
                errors.append(f"emulators/{system.name}/{child.name}: per-game directories are not allowed; keep helpers directly in the system folder")

    for case in cases:
        validate_case(case, errors)

    if errors:
        print("Repository validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(cases)} game cases, {len(shell_files)} shell scripts, and {len(python_files)} Python files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
