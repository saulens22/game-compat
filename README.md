# Game compatibility cases

> [!IMPORTANT]
> This repository was created primarily by AI (OpenAI Codex) under human
> direction. Scripts, package mappings, compatibility conclusions, and upstream
> references should be independently reviewed before use. Human testing and
> corrections are reflected in the final result files where documented.

Browse the searchable GitHub Pages catalog at
[saulens22.github.io/game-compat](https://saulens22.github.io/game-compat/).

See [Using the game setups](USAGE.md) for shared behavior such as Steam
shutdown, portable paths, backups, verification, launch options, and controller
configuration preservation.

See [Linux gaming basics](LINUX_SETUP.md) for the supported native Steam setup,
Proton, graphics drivers, Wayland, controllers, and filesystem expectations.

See [Helper app](HELPER_APP.md) for its launch command, live catalog refresh,
offline fallback, and script-version update behavior.

See [Tested environment](TESTED_ENVIRONMENT.md) for the public hardware,
driver, package, desktop, and Proton snapshot associated with the documented
results.

For the native graphical launcher:

```bash
./launch-gui.sh
```

Pull requests targeting `main` must pass repository structure, JSON, Bash,
ShellCheck, Python syntax, portability, and strict documentation-build checks.
GitHub Pages deployment is restricted to the `main` branch.

## Repository layout

- `steam/<game-slug>-<app-id>/`: Steam editions identified by public App ID.
- `windows/<game-slug>/`: non-Steam Windows/Wine games.
- `emulators/<system>/`: system-level emulation research and game helpers.
- `emulators/frontends/<frontend>/`: shared frontends such as RetroArch,
  regardless of whether their installed build comes from Steam.
- `skills/`: reusable diagnostic procedure and bundled helper scripts.
- `_work/`: ignored local scratch tools and partial audits.

Case directories keep user setup in `README.md`, sanitized final outcomes in
`RESULTS.md`, and agent-only procedure in `AGENTS.md` when needed. Emulated
systems consolidate multiple titles directly in one system directory.

- [GTA classic trilogy research](gta-classic-trilogy-research.md)

## GTA classic trilogy reproduction

With Steam fully exited, configure GTA III, Vice City, and San Andreas in one
run:

```bash
/path/to/game-compat/setup-gta-classic-trilogy.sh
```

The setup uses each game's pinned installer and verifier, writes the full Steam
launch-options lines, selects Proton-GE Latest per App ID, and fails if the
Steam controller configuration changes. The San Andreas verifier rejects the
known unwanted Workshop layout and requires Steam's built-in default gamepad
layout.

## System packages

Shared host capabilities are documented in `requirements-global.txt`; each
game also has its own `requirements.txt`. The installer detects Arch-family,
Ubuntu/Debian, or Fedora systems and maps those capabilities to native package
names. On Arch it uses `yay` when available and otherwise `pacman`; it uses
`apt-get` or `dnf` on the other supported families. With no selector, install
or verify all requirements:

```bash
/path/to/game-compat/install-system-packages.sh
```

Select one game (global requirements are included automatically), multiple
games, or only the global tools:

```bash
./install-system-packages.sh gta3
./install-system-packages.sh vc sa
./install-system-packages.sh global
./install-system-packages.sh --dry-run mk11
./install-system-packages.sh --dry-run --distro ubuntu gta3
```

Selectors accept both short names and directory slugs. The script parses every
selected manifest, ignores comments and blank lines, validates and deduplicates
package names, then passes them to `yay -S --needed`.

## Targeted window screenshots

`skills/wayland-window-capture/scripts/capture-window.sh` captures a game window or Wine dialog through KWin and
saves Wayland-native window metadata beside the PNG. It falls back to XWayland
inspection only for Wine surfaces when `kdotool` is unavailable:

```bash
./skills/wayland-window-capture/scripts/capture-window.sh --name '^Unhandled Exception$' evidence/exception.png
./skills/wayland-window-capture/scripts/capture-window.sh --class 'steam_app_12100' evidence/gta3.png
./skills/wayland-window-capture/scripts/capture-window.sh --id 0x6e0000e evidence/window.png
```

- [Grand Theft Auto III](steam/grand-theft-auto-iii-12100/README.md)
- [Grand Theft Auto: Vice City](steam/grand-theft-auto-vice-city-12110/README.md)
- [Grand Theft Auto: San Andreas](steam/grand-theft-auto-san-andreas-12120/README.md)
- [Mortal Kombat 11](steam/mortal-kombat-11-976310/README.md)
- [RetroArch](emulators/frontends/retroarch/README.md)

## Shared tooling

- `skills/steam-proton-diagnostic/scripts/steam-session.sh`: starts, stops, restarts, or inspects a real Steam client
  in a transient user-systemd service. Use `--unit NAME.service` to give a case
  its own service name.
- `skills/steam-proton-diagnostic/scripts/summarize-diagnostic.sh`: summarizes the standard `telemetry.csv` and
  optional metadata/kernel-error files produced by diagnostic runs.
- `set-steam-launch-options.sh`: while Steam is stopped, replaces and verifies
  one game's complete launch-options value and keeps a timestamped backup.
- `set-steam-compat-tool.sh`: while Steam is stopped, changes and verifies only
  the requested App ID's compatibility-tool mapping and keeps a backup.
- `remove-steam-compat-tool.sh`: while Steam is stopped, removes obsolete
  non-Steam compatibility mappings with backup and verification.
- `bottles-game.sh` and `bottles-winetricks.sh`: manage isolated Bottles cases
  and install verified dependencies with each bottle's selected runner.
- `add-bottles-steam-shortcut.sh`: optional, case-controlled direct Steam
  integration for a verified win64 bottle. It keeps one shortcut per game and
  warns that Bottles and Steam Proton sharing a prefix is brittle. Pre-launch
  helpers are time-bounded and may not start Bottles, Wine, Proton or Steam, so
  helper services cannot leave a shortcut permanently marked Running.
- `wine-reg-set-dword.sh`: makes one locked DWORD change in an inactive Bottles
  Flatpak prefix without starting Wine; intended for safe, bounded pre-launch
  preparation when a game rewrites a display or compatibility setting on exit.
- `skills/steam-proton-diagnostic/scripts/game-config-snapshot.sh`: creates verified per-game config snapshots with an
  exact source-path manifest, and can list, diff, verify, or restore them.
- `skills/steam-proton-diagnostic/scripts/experiment-guard.sh`: checks canonical test signatures against a per-game
  `experiments.tsv` and rejects accidental duplicates. The strict columns are
  signature SHA-256, timestamp, canonical signature, and one-line result.

Game-specific wrappers and launch logic remain inside each game directory.

## Reusable diagnostic skills

- `skills/mangohud-capture`: bounded MangoHud logging and output validation.
- `skills/steam-proton-diagnostic`: one-variable Steam/Proton experiments.
- `skills/wayland-window-capture`: targeted KDE Wayland/XWayland evidence.

Skills contain agent procedure. User operation stays in `README.md`; sanitized
final findings stay in each game's separate `RESULTS.md`.
