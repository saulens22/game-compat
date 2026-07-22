#!/usr/bin/env python3
"""Small native launcher for the documented game compatibility scripts."""

from __future__ import annotations

import argparse
import re
import shlex
import shutil
import subprocess
import sys
import tkinter as tk
import json
import urllib.error
import urllib.request
import webbrowser
from dataclasses import dataclass
from pathlib import Path
from tkinter import messagebox, ttk


ROOT = Path(__file__).resolve().parent
PAGES = "https://saulens22.github.io/game-compat"
REPOSITORY = "saulens22/game-compat"
CACHE = Path.home() / ".cache" / "game-compat" / "catalog.json"


@dataclass
class Game:
    title: str
    case: Path
    relative: Path
    app_id: str | None
    readme: str
    version: str = "unversioned"

    @property
    def selector(self) -> str:
        return self.relative.as_posix()

    def script(self, name: str) -> Path:
        return self.case / name


def section(markdown: str, name: str) -> str:
    match = re.search(
        rf"^## {re.escape(name)}\s*$\n(.*?)(?=^## |\Z)", markdown, re.MULTILINE | re.DOTALL
    )
    return match.group(1).strip() if match else "Not documented."


def plain(markdown: str) -> str:
    text = re.sub(r"\[([^]]+)]\([^)]+\)", r"\1", markdown)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"^[-*] ", "• ", text, flags=re.MULTILINE)
    return text


def discover_local_games() -> list[Game]:
    games: list[Game] = []
    roots = (ROOT / "steam", ROOT / "windows")
    for base in roots:
        if not base.is_dir():
            continue
        for readme in sorted(base.glob("*/README.md")):
            text = readme.read_text(encoding="utf-8")
            heading = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
            app = re.search(r"-(\d+)$", readme.parent.name) if base.name == "steam" else None
            games.append(Game(
                heading.group(1) if heading else readme.parent.name,
                readme.parent,
                readme.parent.relative_to(ROOT),
                app.group(1) if app else None,
                text,
                local_version(readme.parent),
            ))
    emulator_root = ROOT / "emulators"
    if emulator_root.is_dir():
        emulator_readmes = list(emulator_root.glob("*/README.md"))
        emulator_readmes += list((emulator_root / "frontends").glob("*/README.md"))
        for readme in sorted(emulator_readmes):
            if not (readme.parent / "versions.json").is_file():
                continue
            text = readme.read_text(encoding="utf-8")
            heading = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
            games.append(Game(
                heading.group(1) if heading else readme.parent.name,
                readme.parent,
                readme.parent.relative_to(ROOT),
                None,
                text,
                local_version(readme.parent),
            ))
    return games


def local_version(case: Path) -> str:
    try:
        return str(json.loads((case / "versions.json").read_text(encoding="utf-8"))["current"])
    except (OSError, ValueError, KeyError):
        return "unversioned"


def refresh_catalog() -> tuple[list[Game], str]:
    """Fetch README-backed catalog data from the current GitHub main branch."""
    request = urllib.request.Request(
        f"https://api.github.com/repos/{REPOSITORY}/git/trees/main?recursive=1",
        headers={"Accept": "application/vnd.github+json", "User-Agent": "game-compat-launcher"},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            tree = json.load(response)["tree"]
        blob_paths = {
            item["path"] for item in tree if item.get("type") == "blob"
        }
        paths = sorted(
            item["path"] for item in tree
            if item.get("type") == "blob" and re.fullmatch(
                r"(?:steam|windows)/[^/]+/README\.md|emulators/(?:frontends/[^/]+|[^/]+)/README\.md",
                item["path"],
            )
            and str(Path(item["path"]).parent / "versions.json") in blob_paths
        )
        records = []
        for path in paths:
            url = f"https://raw.githubusercontent.com/{REPOSITORY}/main/{path}"
            readme_request = urllib.request.Request(url, headers={"User-Agent": "game-compat-launcher"})
            with urllib.request.urlopen(readme_request, timeout=8) as response:
                markdown = response.read().decode("utf-8")
            relative = Path(path).parent
            version_url = f"https://raw.githubusercontent.com/{REPOSITORY}/main/{relative.as_posix()}/versions.json"
            try:
                version_request = urllib.request.Request(version_url, headers={"User-Agent": "game-compat-launcher"})
                with urllib.request.urlopen(version_request, timeout=8) as response:
                    version = str(json.load(response)["current"])
            except (OSError, ValueError, KeyError, urllib.error.URLError):
                version = "unversioned"
            heading = re.search(r"^#\s+(.+)$", markdown, re.MULTILINE)
            app = re.search(r"-(\d+)$", relative.name) if relative.parts[0] == "steam" else None
            records.append({
                "title": heading.group(1) if heading else relative.name,
                "relative": relative.as_posix(),
                "app_id": app.group(1) if app else None,
                "readme": markdown,
                "version": version,
            })
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(records), encoding="utf-8")
        return catalog_games(records), "Catalog refreshed from GitHub main."
    except (OSError, KeyError, ValueError, urllib.error.URLError) as exc:
        try:
            records = json.loads(CACHE.read_text(encoding="utf-8"))
            return catalog_games(records), f"GitHub refresh failed; using cached catalog ({exc})."
        except (OSError, ValueError, KeyError):
            return discover_local_games(), f"GitHub refresh failed; using bundled catalog ({exc})."


def catalog_games(records: list[dict[str, object]]) -> list[Game]:
    games = []
    for record in records:
        relative = Path(str(record["relative"]))
        games.append(Game(
            str(record["title"]), ROOT / relative, relative,
            str(record["app_id"]) if record.get("app_id") else None,
            str(record["readme"]),
            str(record.get("version", "unversioned")),
        ))
    return games


def terminal_command(command: list[str]) -> list[str] | None:
    rendered = shlex.join(command)
    script = (
        f"cd {shlex.quote(str(ROOT))}; {rendered}; status=$?; "
        "printf '\\nCommand finished with status %s.\\n' \"$status\"; "
        "read -r -p 'Press Enter to close this window...'; exit \"$status\""
    )
    choices = (
        ("konsole", ["konsole", "-e", "bash", "-lc", script]),
        ("kgx", ["kgx", "--", "bash", "-lc", script]),
        ("gnome-terminal", ["gnome-terminal", "--", "bash", "-lc", script]),
        ("xfce4-terminal", ["xfce4-terminal", "--hold", "-e", f"bash -lc {shlex.quote(script)}"]),
        ("xterm", ["xterm", "-hold", "-e", "bash", "-lc", script]),
    )
    for executable, invocation in choices:
        if shutil.which(executable):
            return invocation
    return None


class Launcher(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Linux Game Compatibility")
        width = min(1500, int(self.winfo_screenwidth() * 0.85))
        height = min(1000, int(self.winfo_screenheight() * 0.85))
        self.geometry(f"{width}x{height}")
        self.minsize(850, 520)
        self.games, catalog_status = refresh_catalog()
        self.selected: Game | None = None
        self.status = tk.StringVar(value=catalog_status)
        self._build()
        if self.games:
            self.game_list.selection_set(0)
            self._select()

    def _build(self) -> None:
        toolbar = ttk.Frame(self, padding=10)
        toolbar.pack(fill=tk.X)
        ttk.Button(toolbar, text="Beginner guide", command=lambda: webbrowser.open(f"{PAGES}/usage/")).pack(side=tk.LEFT)
        ttk.Button(toolbar, text="Linux basics", command=lambda: webbrowser.open(f"{PAGES}/linux-setup/")).pack(side=tk.LEFT, padx=(8, 0))
        ttk.Button(toolbar, text="Tested environment", command=lambda: webbrowser.open(f"{PAGES}/tested-environment/")).pack(side=tk.LEFT, padx=8)
        ttk.Button(toolbar, text="Repository", command=lambda: webbrowser.open("https://github.com/saulens22/game-compat")).pack(side=tk.LEFT)

        body = ttk.Panedwindow(self, orient=tk.HORIZONTAL)
        body.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))
        left = ttk.Frame(body, padding=8)
        right = ttk.Frame(body, padding=8)
        body.add(left, weight=2)
        body.add(right, weight=5)

        ttk.Label(left, text="Games", font=("TkDefaultFont", 14, "bold")).pack(anchor=tk.W, pady=(0, 8))
        self.game_list = tk.Listbox(left, exportselection=False, width=38)
        self.game_list.pack(fill=tk.BOTH, expand=True)
        for game in self.games:
            menu_title = re.sub(r"\s+\([^)]*\)$", "", game.title)
            menu_title = re.sub(r"\s+on Linux$", "", menu_title)
            label = menu_title + (f" (Steam {game.app_id})" if game.app_id else "")
            self.game_list.insert(tk.END, label)
        self.game_list.bind("<<ListboxSelect>>", lambda _event: self._select())

        right.columnconfigure(0, weight=1)
        right.rowconfigure(1, weight=1)
        self.heading = ttk.Label(right, text="", font=("TkDefaultFont", 16, "bold"), wraplength=680)
        self.heading.grid(row=0, column=0, sticky=tk.EW)
        summary_frame = ttk.Frame(right)
        summary_frame.grid(row=1, column=0, sticky=tk.NSEW, pady=10)
        summary_frame.columnconfigure(0, weight=1)
        summary_frame.rowconfigure(0, weight=1)
        self.summary = tk.Text(summary_frame, wrap=tk.WORD, state=tk.DISABLED, height=5, padx=8, pady=8)
        summary_scroll = ttk.Scrollbar(summary_frame, orient=tk.VERTICAL, command=self.summary.yview)
        self.summary.configure(yscrollcommand=summary_scroll.set)
        self.summary.grid(row=0, column=0, sticky=tk.NSEW)
        summary_scroll.grid(row=0, column=1, sticky=tk.NS)

        actions = ttk.Frame(right)
        actions.grid(row=2, column=0, sticky=tk.EW)
        self.buttons: dict[str, ttk.Button] = {}
        specs = (
            ("docs", "Read game page", self.open_docs),
            ("packages", "Install requirements", self.install_packages),
            ("setup", "Apply setup", self.setup),
            ("verify", "Verify", self.verify),
            ("rollback", "Undo fixes", self.rollback),
            ("copy", "Copy launch options", self.copy_launch),
            ("update", "Get script update", self.open_update),
            ("steam", "Open in Steam", self.open_steam),
        )
        for index, (key, label, callback) in enumerate(specs):
            button = ttk.Button(actions, text=label, command=callback)
            button.grid(row=index // 4, column=index % 4, sticky=tk.EW, padx=(0, 6), pady=3)
            self.buttons[key] = button
        for column in range(4):
            actions.columnconfigure(column, weight=1)
        ttk.Label(right, textvariable=self.status, wraplength=680).grid(row=3, column=0, sticky=tk.EW, pady=(8, 0))

    def _select(self) -> None:
        selection = self.game_list.curselection()
        if not selection:
            return
        self.selected = self.games[selection[0]]
        game = self.selected
        self.heading.configure(text=game.title)
        installed = local_version(game.case)
        content = "\n\n".join((
            f"SCRIPT VERSION\nOnline: {game.version} | Installed: {installed}",
            "TESTED WITH\n" + plain(section(game.readme, "Tested with")),
            "FINAL BEHAVIOR\n" + plain(section(game.readme, "Final behavior")),
            "NOT YET FIXED\n" + plain(section(game.readme, "TODO (not yet fixed)")),
        ))
        self.summary.configure(state=tk.NORMAL)
        self.summary.delete("1.0", tk.END)
        self.summary.insert("1.0", content)
        self.summary.configure(state=tk.DISABLED)
        for key, script in (("setup", "setup-steam.sh"), ("verify", "verify-install.sh"), ("rollback", "rollback-fixes.sh")):
            self.buttons[key].configure(state=tk.NORMAL if game.script(script).is_file() else tk.DISABLED)
        self.buttons["packages"].configure(
            state=tk.NORMAL if game.script("requirements.txt").is_file() else tk.DISABLED
        )
        self.buttons["steam"].configure(state=tk.NORMAL if game.app_id else tk.DISABLED)
        self.buttons["update"].configure(
            state=tk.NORMAL
            if game.version != "unversioned" and installed != game.version
            else tk.DISABLED
        )
        unavailable = not game.case.is_dir()
        if unavailable:
            self.status.set("Current catalog data loaded from GitHub; download or clone the scripts to enable actions.")
        else:
            self.status.set("Choose an action. Commands open in a terminal and show their complete output.")

    def run_terminal(self, command: list[str]) -> None:
        invocation = terminal_command(command)
        if not invocation:
            messagebox.showerror("No terminal found", "Install Konsole, GNOME Terminal, XFCE Terminal, or xterm.")
            return
        subprocess.Popen(invocation, start_new_session=True)

    def open_docs(self) -> None:
        if self.selected:
            webbrowser.open(f"{PAGES}/{self.selected.case.name}/")

    def install_packages(self) -> None:
        if self.selected:
            self.run_terminal([str(ROOT / "install-system-packages.sh"), self.selected.selector])

    def setup(self) -> None:
        if not self.selected:
            return
        if subprocess.run(["pgrep", "-x", "steam"], stdout=subprocess.DEVNULL).returncode == 0:
            messagebox.showwarning("Exit Steam first", "Use Steam → Exit, wait for Steam to close, then press Apply setup again.")
            return
        if messagebox.askokcancel("Apply documented setup?", "This installs the fixes described on the game page and updates this game's Steam configuration. Local rollback copies are created first."):
            self.run_terminal([str(self.selected.script("setup-steam.sh"))])

    def verify(self) -> None:
        if self.selected:
            self.run_terminal([str(self.selected.script("verify-install.sh"))])

    def rollback(self) -> None:
        if self.selected and messagebox.askyesno("Undo fixes?", "Restore the local pre-fix snapshot for this game?"):
            self.run_terminal([str(self.selected.script("rollback-fixes.sh"))])

    def copy_launch(self) -> None:
        if not self.selected:
            return
        block = re.search(r"^## Steam launch options.*?```(?:text)?\n(.*?)\n```", self.selected.readme, re.MULTILINE | re.DOTALL)
        if not block:
            messagebox.showerror("Not documented", "No complete launch-options line was found.")
            return
        value = block.group(1).strip()
        self.clipboard_clear()
        self.clipboard_append(value)
        self.status.set(f"Copied complete launch options: {value}")

    def open_steam(self) -> None:
        if self.selected and self.selected.app_id:
            webbrowser.open(f"steam://store/{self.selected.app_id}")

    def open_update(self) -> None:
        if self.selected:
            webbrowser.open(f"{PAGES}/{self.selected.case.name}/#script-versions")


def self_test() -> int:
    games = discover_local_games()
    errors: list[str] = []
    if not games:
        errors.append("no local game cases were discovered")
    selectors: set[str] = set()
    for game in games:
        if game.selector in selectors:
            errors.append(f"duplicate selector: {game.selector}")
        selectors.add(game.selector)
        if section(game.readme, "Tested with") == "Not documented.":
            errors.append(f"missing Tested with section: {game.selector}")
        if section(game.readme, "Final behavior") == "Not documented.":
            errors.append(f"missing Final behavior section: {game.selector}")
        if section(game.readme, "TODO (not yet fixed)") == "Not documented.":
            errors.append(f"missing TODO section: {game.selector}")
        if game.version == "unversioned":
            errors.append(f"missing or invalid versions.json: {game.selector}")
    if errors:
        print("Launcher self-test failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Launcher self-test passed for {len(games)} local cases.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="validate local catalog discovery without opening a window")
    args = parser.parse_args()
    if not (ROOT / "steam").is_dir():
        print("Run this launcher from an extracted game-compat bundle or repository clone.", file=sys.stderr)
        raise SystemExit(1)
    if args.self_test:
        raise SystemExit(self_test())
    Launcher().mainloop()
