#!/usr/bin/env python3
"""Prepare tracked game Markdown and downloads for MkDocs Material."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import zipfile
from pathlib import Path


DOWNLOAD_SUFFIXES = {".sh", ".py", ".c", ".cpp", ".conf", ".asi"}

HELP = {
    "setup-steam.sh": ("Configure Steam launch", "Adds or updates this case's documented Steam integration; read the case page to see whether Steam is optional."),
    "prepare-steam-launch.sh": ("Prepare a direct Steam launch", "Resets display-dependent settings immediately before Steam Proton starts the game."),
    "setup-bottle.sh": ("Create the isolated bottle", "Verifies the source file and creates the complete one-game Bottles installation."),
    "configure-fixes.sh": ("Configure the compatibility fixes", "Applies the verified self-contained paths, codec preference and Windows compatibility identity."),
    "install-d2gi.sh": ("Install D2GI", "Downloads the pinned D2GI release, verifies its checksum and installs the modern DirectDraw wrapper."),
    "rollback-d2gi.sh": ("Roll back D2GI", "Warns before removing D2GI and restores any files preserved by the installer."),
    "launch.sh": ("Launch the game", "Starts the registered program through its dedicated Bottles environment."),
    "verify-install.sh": ("Check the installation", "Performs a read-only check of the installed fixes and configuration."),
    "rollback-fixes.sh": ("Undo the fixes", "Restores the local backup captured before the fixes were installed."),
    "install-fixes.sh": ("Install fixes only", "Installs the pinned game fixes without configuring the complete Steam launch path."),
    "install-intro-codecs.sh": ("Try intro codecs", "Installs the case's experimental intro-video codec path; read the case results first."),
    "build-controller-skip.sh": ("Build controller intro skipping", "Builds the optional controller-aware intro helper."),
    "build-re3.sh": ("Build native re3", "Builds the optional native re3 experiment; this is not the recommended Steam route."),
    "launch-re3.sh": ("Launch native re3", "Runs the separately built native re3 experiment."),
    "launch-with-intros.sh": ("Launch with visible intros", "Runs the native intro-video wrapper and then the regular Steam game."),
    "stage-owned-assets.sh": ("Stage local re3 assets", "Copies required assets from the installed GTA III files for re3."),
    "run-dx12-diagnostic.sh": ("Run a bounded DX12 diagnostic", "Captures a timed MK11 DX12 diagnostic run; arguments are described in the case README."),
    "update-cores.sh": ("Update managed Libretro cores", "Downloads the documented current official cores, backs up existing binaries, and records source URLs and SHA-256 hashes."),
    "install-mgba-xbox-label-remap.sh": ("Use Xbox labels in mGBA", "Optionally maps Xbox A to GBA A and Xbox B to GBA B without changing menus or other cores."),
    "steam-session.sh": ("Inspect the Steam session", "Shared support helper used to inspect or control a diagnostic Steam session."),
    "summarize-diagnostic.sh": ("Summarize a diagnostic", "Produces a concise summary from a completed diagnostic directory."),
    "controller-skip.c": ("Controller intro helper source", "C source used by build-controller-skip.sh; it is not run directly."),
    "mpv-intro-input.conf": ("Intro player input configuration", "Input bindings consumed by the intro wrapper; keep it beside the scripts."),
    "fix-installer-directx.sh": ("Repair the NBA Live 07 installer", "Replaces only the obsolete DirectX setup engine after preserving and verifying its original files."),
    "configure-runtime.sh": ("Configure the NBA Live 07 runtime", "Installs the documented runtime components through Bottles Winetricks and repairs runner-matched WineD3D support files."),
    "fix-clean-exit.sh": ("Repair NBA Live 07 shutdown", "Applies or rolls back the checksum-guarded branch patch that lets the confirmed executable terminate cleanly."),
    "install-widescreen.sh": ("Install the experimental NBA resolution plugin", "Installs the documented ASI loader and resolution plugin; the case page explains why the present widescreen result is not accepted."),
    "apply-official-update.sh": ("Apply the NBA Live 07 update", "Applies a player-supplied matching official update after checking the installed edition and preserving rollback data."),
    "build.sh": ("Build the NBA controller fallback", "Reproducibly compiles the included controller-profile fallback source for the supported 32-bit executable."),
    "install.sh": ("Install the NBA controller fallback", "Verifies the executable and plugin hashes, then installs, inspects, or rolls back the native controller-profile fallback."),
    "nba_controller_profile_fallback.cpp": ("NBA controller fallback source", "Auditable C++ source for the profile fallback used by modern Xbox-family controllers."),
    "NBAControllerProfileFallback-v2.asi": ("NBA controller fallback binary", "Reproducibly built 32-bit ASI tested with the executable hash documented on the NBA Live 07 page."),
    "requirements.txt": ("System requirements", "Portable capability list consumed by the repository's system-package installer."),
}

ACTION_ORDER = {"setup-steam.sh": 0, "verify-install.sh": 1, "rollback-fixes.sh": 2}

BUNDLE_SHARED = {
    "HELPER_APP.md",
    "LINUX_SETUP.md",
    "TESTED_ENVIRONMENT.md",
    "USAGE.md",
    ".env.example",
    "add-bottles-steam-shortcut.sh",
    "add-steam-shortcut.py",
    "bottles-game.sh",
    "bottles-winetricks.sh",
    "game-compat-launcher.py",
    "install-system-packages.sh",
    "launch-gui.sh",
    "requirements-global.txt",
    "python-requirements.txt",
    "run-python-tool.sh",
    "remove-steam-compat-tool.sh",
    "set-steam-compat-tool.sh",
    "set-steam-launch-options.sh",
    "lib/steam-paths.sh",
    "lib/load-env.sh",
    "skills/steam-proton-diagnostic/scripts/experiment-guard.sh",
    "skills/steam-proton-diagnostic/scripts/game-config-snapshot.sh",
    "skills/steam-proton-diagnostic/scripts/steam-session.sh",
    "skills/steam-proton-diagnostic/scripts/summarize-diagnostic.sh",
}

SHARED_HELP = {
    "add-bottles-steam-shortcut.sh": "Optionally creates one direct Steam shortcut for a verified win64 Bottles prefix, preserving required launch options and warning about shared-prefix risk.",
    "add-steam-shortcut.py": "Safely backs up and manages native non-Steam shortcuts while protecting Steam's live shortcut database.",
    "bottles-winetricks.sh": "Installs verified dependencies through Bottles' bundled Winetricks and the bottle's selected runner.",
    "run-python-tool.sh": "Creates an ignored pinned Python virtual environment and runs repository Python helpers inside it.",
    "bottles-game.sh": "Creates, inspects, registers, and launches one isolated Bottles environment per non-Steam Windows game without managing host packages.",
    "launch-gui.sh": "Starts the native graphical helper and offers to install Python Tk when it is missing.",
    "game-compat-launcher.py": "Graphical helper source; it refreshes public catalog data from GitHub when launched.",
    "install-system-packages.sh": "Installs the documented host packages for all games or for a selected game on Arch, Debian/Ubuntu, or Fedora.",
    "setup-gta-classic-trilogy.sh": "Runs the complete maintained setup for GTA III, Vice City, and San Andreas.",
    "set-steam-client-channel.sh": "Safely selects a Steam client channel while preserving a backup of the previous configuration.",
    "remove-steam-compat-tool.sh": "Removes obsolete non-Steam compatibility mappings while Steam is stopped, with backup and verification.",
    "set-steam-compat-tool.sh": "Selects a compatibility tool for one Steam App ID with backup and verification.",
    "set-steam-launch-options.sh": "Writes the complete launch-options line for one Steam App ID with backup and verification.",
    "experiment-guard.sh": "Prevents an identical game experiment from being repeated without a changed condition.",
    "game-config-snapshot.sh": "Creates, verifies, compares, and restores checksummed game-configuration snapshots.",
    "steam-session.sh": "Collects and controls the Steam process state needed by a bounded diagnostic run.",
    "summarize-diagnostic.sh": "Summarizes the logs produced by a completed Steam/Proton diagnostic run.",
    "capture-window.sh": "Captures one selected Wayland window together with identifying window metadata.",
}


def tracked_files(root: Path) -> set[Path]:
    output = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=root,
    )
    return {
        path for value in output.rstrip(b"\0").split(b"\0") if value
        if (path := root / value.decode()).is_file()
    }


def heading(text: str, fallback: str) -> str:
    match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else fallback


def without_first_heading(text: str) -> str:
    return re.sub(r"^#\s+.+\n+", "", text, count=1, flags=re.MULTILINE)


def platform_label(relative: Path) -> str:
    if relative.parts[0] == "steam":
        return "Steam"
    if relative.parts[0] == "windows":
        return "Windows"
    if relative.parts[0] == "emulators":
        return "Emulators"
    return relative.parts[0].title()


def copy_download(source: Path, root: Path, docs: Path) -> Path:
    relative = source.relative_to(root)
    destination = docs / "downloads" / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    return destination


def make_bundle(
    case: Path, sources: list[Path], root: Path, docs: Path, tracked: set[Path]
) -> Path:
    destination = docs / "downloads" / case.relative_to(root) / f"{case.name}-scripts.zip"
    destination.parent.mkdir(parents=True, exist_ok=True)
    bundle_sources = set(sources)
    bundle_sources.update(
        path for path in tracked
        if case in path.parents and path.name != "AGENTS.md"
    )
    bundle_sources.update(root / relative for relative in BUNDLE_SHARED)
    bundle_sources.update(
        path for path in (
            case / "README.md", case / "RESULTS.md", case / "upstream.json", case / "versions.json"
        )
        if path in tracked
    )
    missing = sorted(path.relative_to(root) for path in bundle_sources if path not in tracked)
    if missing:
        raise RuntimeError(f"bundle inputs are not tracked: {', '.join(map(str, missing))}")
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for source in sorted(bundle_sources):
            archive.write(source, Path("game-compat") / source.relative_to(root))
    return destination


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--config-output", required=True, type=Path)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    docs = args.output.resolve()
    config_output = args.config_output.resolve()
    tracked = tracked_files(root)
    if docs.exists():
        shutil.rmtree(docs)
    docs.mkdir(parents=True)

    games = []
    for readme in sorted(tracked):
        relative = readme.relative_to(root)
        if readme.name != "README.md" or relative.parts[0] not in {"steam", "windows", "emulators"}:
            continue
        if len(relative.parts) < 2 or readme.parent == root / relative.parts[0]:
            continue
        case = readme.parent
        case_relative = case.relative_to(root)
        results = case / "RESULTS.md"
        requirements = case / "requirements.txt"
        if results not in tracked or requirements not in tracked:
            continue

        readme_text = re.sub(
            r"]\((?:\./)?RESULTS\.md\)",
            "](#final-results)",
            readme.read_text(encoding="utf-8"),
        )
        readme_text = readme_text.replace(
            "](../../USAGE.md)",
            "](usage.md)",
        )
        readme_text = readme_text.replace(
            "](../../TESTED_ENVIRONMENT.md)",
            "](tested-environment.md)",
        ).replace(
            "](../../../TESTED_ENVIRONMENT.md)",
            "](tested-environment.md)",
        )
        results_text = results.read_text(encoding="utf-8")
        title = heading(readme_text, case.name)
        platform = platform_label(case_relative)
        app_match = re.search(r"-(\d+)$", case.name)
        if platform == "Steam" and app_match:
            edition = f"App ID {app_match.group(1)}"
        elif case_relative.parts[0] == "emulators":
            edition = "Frontend" if case_relative.parts[1] == "frontends" else case_relative.parts[1].upper()
        else:
            edition = ""
        page_path = docs / f"{case.name}.md"

        upstream_file = case / "upstream.json"
        upstream = json.loads(upstream_file.read_text(encoding="utf-8")) if upstream_file in tracked else []
        downloads = sorted(
            (
                path for path in tracked
                if case in path.parents
                and path.suffix in DOWNLOAD_SUFFIXES
                and path.name != "AGENTS.md"
            ),
            key=lambda path: (ACTION_ORDER.get(path.name, 10), path.name),
        )
        downloads.append(requirements)

        versions_file = case / "versions.json"
        versions = json.loads(versions_file.read_text(encoding="utf-8")) if versions_file in tracked else {"current": "unversioned", "history": []}
        lines = [readme_text.rstrip(), "", "---", "", "## Final results", "", without_first_heading(results_text).rstrip(), "", "## Script versions", "", f"Current version: **{versions['current']}**", ""]
        for item in versions.get("history", []):
            lines.extend([f'=== "{item["version"]}"', "", f'    {item["summary"]}', ""])
        lines.extend(["The current bundle below is the update path. Clone users can run `git pull --ff-only`; bundle users download and extract the newer bundle to a new directory, verify it, and then replace the old copy.", "", "## Scripts and downloads", ""])
        bundle = make_bundle(case, downloads, root, docs, tracked)
        bundle_link = bundle.relative_to(docs)
        lines.extend([
            "### Complete script bundle",
            "",
            "Download this ZIP for a self-contained copy of this case's scripts and their shared helpers.",
            "",
            f"[Download {case.name}-scripts.zip]({bundle_link.as_posix()}){{: download }}",
            "",
            "For the graphical launcher, extract the ZIP, open its `game-compat` directory in a terminal, and run:",
            "",
            "```bash",
            "./launch-gui.sh",
            "```",
            "",
        ])
        recommended = next((source for source in downloads if source.name == "setup-steam.sh"), None)
        if recommended:
            lines.extend([
                "Or apply this case entirely from the terminal. Fully exit Steam before the second command:",
                "",
                "```bash",
                f"./install-system-packages.sh {case_relative.as_posix()}",
                f"./{case_relative.as_posix()}/setup-steam.sh",
                "```",
                "",
            ])
        lines.extend([
            "### Individual files",
            "",
            "Use the complete ZIP for installation. Individual files are provided for inspection or replacing one file inside an already extracted bundle.",
            "",
        ])
        for source in downloads:
            destination = copy_download(source, root, docs)
            link = destination.relative_to(docs)
            action_title, description = HELP.get(source.name, (source.name, "Supporting file used by this case's documented setup or reproducible build."))
            lines.extend([f"#### {action_title}", "", description, ""])
            lines.extend([f"[Download {source.name}]({link.as_posix()}){{: download }}", ""])
        lines.extend(["", "## Game or frontend links", ""])
        if platform == "Steam" and app_match:
            app_id = app_match.group(1)
            lines.extend([
                f"- [Steam store](https://store.steampowered.com/app/{app_id}/)",
                f"- [Steam Community](https://steamcommunity.com/app/{app_id}/)",
                f"- [ProtonDB reports](https://www.protondb.com/app/{app_id})",
                f"- [SteamDB information](https://steamdb.info/app/{app_id}/)",
            ])
        else:
            lines.append("- No storefront or compatibility-database links recorded.")
        lines.extend(["", "## Fix and project links", ""])
        lines.extend(f'- [{item["name"]}]({item["url"]})' for item in upstream)
        if not upstream:
            lines.append("- No upstream links recorded.")
        lines.extend(["", f"[View this case on GitHub](https://github.com/saulens22/game-compat/tree/main/{case_relative.as_posix()})", ""])
        page_path.write_text("\n".join(lines), encoding="utf-8")
        games.append((title, platform, edition, page_path.relative_to(docs), (case / "setup-steam.sh") in tracked))

    shared = sorted(
        path for path in tracked
        if path.suffix in DOWNLOAD_SUFFIXES
        and (path.parent == root or ("skills" in path.parts and "scripts" in path.parts))
    )
    tools_lines = [
        "# Shared downloads",
        "",
        "These utilities are useful across more than one game. Game-specific setup bundles are available from each game's page.",
        "",
    ]
    for source in shared:
        destination = copy_download(source, root, docs)
        description = SHARED_HELP.get(source.name, "Supporting utility used by the documented compatibility workflows.")
        tools_lines.extend([
            f"## {source.name}",
            "",
            description,
            "",
            f"[Download {source.name}]({destination.relative_to(docs).as_posix()}){{: download }}",
            "",
        ])
    (docs / "tools.md").write_text("\n".join(tools_lines) + "\n", encoding="utf-8")
    usage_text = (root / "USAGE.md").read_text(encoding="utf-8").replace(
        "](HELPER_APP.md)", "](helper-app.md)"
    ).replace("](LINUX_SETUP.md)", "](linux-setup.md)")
    (docs / "usage.md").write_text(usage_text, encoding="utf-8")
    shutil.copy2(root / "TESTED_ENVIRONMENT.md", docs / "tested-environment.md")
    helper_text = (root / "HELPER_APP.md").read_text(encoding="utf-8").replace(
        "](HELPER_APP.md)", "](helper-app.md)"
    )
    (docs / "helper-app.md").write_text(helper_text, encoding="utf-8")
    linux_text = (root / "LINUX_SETUP.md").read_text(encoding="utf-8").replace(
        "](TESTED_ENVIRONMENT.md)", "](tested-environment.md)"
    ).replace("](USAGE.md)", "](usage.md)")
    (docs / "linux-setup.md").write_text(linux_text, encoding="utf-8")

    index = [
        "# Linux game compatibility setups",
        "",
        '!!! warning "AI-created repository"',
        "    This repository was created primarily by OpenAI Codex under human direction.",
        "    Independently review scripts, package mappings, and conclusions before use.",
        "",
        "These pages document tested Linux fixes, exact Steam editions, reproducible setup scripts, rollback steps, and approaches that did not work.",
        "",
        "## Start here",
        "",
        "1. Use the native Linux Steam package, not Flatpak, and own the exact edition shown by its App ID.",
        "2. Install and run the unmodified game once.",
        "3. Open your game's page below and read **Default behavior**, **Final behavior**, and **TODO**.",
        "4. Download its **complete script bundle** or clone the repository.",
        "5. Run `./launch-gui.sh`, or follow **Quick commands** in a terminal.",
        "6. Fully exit Steam before applying a setup.",
        "7. Restart Steam, launch the game, and run the provided verifier if anything looks wrong.",
        "",
        "[Read Linux gaming basics](linux-setup.md), the [beginner setup guide](usage.md), or the [helper app guide](helper-app.md).",
        "",
        "Use search for a game, symptom, controller, codec, Proton version, or fix.",
        "",
        "## Documented cases",
        "",
        "| Case | System or edition | Documented outcome |",
        "| :--- | :--- | :--- |",
    ]
    for title, platform, edition, page, has_setup in games:
        display_title = re.sub(r"\s+\([^)]*\)$", "", title)
        display_title = re.sub(r"\s+on Linux$", "", display_title)
        app_id = edition.removeprefix("App ID ")
        if platform == "Steam" and app_id:
            edition_cell = f"[Steam App ID {app_id}](https://store.steampowered.com/app/{app_id}/)"
        elif platform == "Emulators":
            edition_cell = edition
        else:
            edition_cell = platform
        outcome = "Reproducible setup available" if has_setup else "Research documented; no completed fix"
        index.append(f"| [{display_title}]({page.as_posix()}) | {edition_cell} | {outcome} |")
    index.extend([
        "",
        "A completed setup includes installation, verification, and rollback. A research-only case records tested approaches and remaining problems without claiming a fix.",
        "",
        "## More resources",
        "",
        "- [Using the game setups](usage.md)",
        "- [Linux gaming basics](linux-setup.md)",
        "- [Helper app](helper-app.md)",
        "- [Tested environment](tested-environment.md)",
        "- [Shared downloads](tools.md)",
        "",
    ])
    (docs / "index.md").write_text("\n".join(index), encoding="utf-8")

    config = (root / "mkdocs.yml").read_text(encoding="utf-8").rstrip()
    nav = [
        "",
        "nav:",
        "  - Home: index.md",
        "  - Getting started:",
        "      - Using the setups: usage.md",
        "      - Linux gaming basics: linux-setup.md",
        "      - Helper app: helper-app.md",
        "      - Tested environment: tested-environment.md",
    ]
    grouped: dict[str, list[tuple[str, str, Path]]] = {}
    for title, platform, edition, page, _has_setup in games:
        grouped.setdefault(platform, []).append((title, edition, page))
    for platform, entries in grouped.items():
        nav.append(f"  - {json.dumps(platform)}:")
        for title, edition, page in entries:
            identifier = edition.removeprefix("App ID ") if edition.startswith("App ID ") else ""
            menu_title = re.sub(r"\s+\([^)]*\)$", "", title)
            menu_title = re.sub(r"\s+on Linux$", "", menu_title)
            label = f"{menu_title} (App ID {identifier})" if identifier else menu_title
            nav.append(f"      - {json.dumps(label)}: {page.as_posix()}")
    nav.append("  - Shared downloads: tools.md")
    config_output.write_text(config + "\n" + "\n".join(nav) + "\n", encoding="utf-8")
    print(f"Prepared {len(games)} game pages in {docs}")


if __name__ == "__main__":
    main()
