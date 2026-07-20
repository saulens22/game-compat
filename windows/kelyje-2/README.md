# Kelyje II

Lithuanian version 7.3 of *Hard Truck 2*, running on Linux in one
isolated Bottles bottle. Controller support was intentionally not investigated.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md), captured 2026-07-20.
- Verified version 7.3 source-file fingerprint: SHA-256 `9b80360c004bb5eb4aab3de6aa27e76b060867a796895de5bc8ce5ec8957b5b1`.
- `RigNRoll.exe` version 7.3 dated 2001, SHA-256 `b7deb5fca7c4f2ab0eb8e02c3aae441eed13e3c4bb53797afd2df35f0721cc28`.
- Bottles Flatpak 64.1, dedicated 32-bit `kelyje-2` gaming bottle, Soda 9.0-1 runner.
- Wine compatibility identity: Windows XP (`CurrentVersion 5.1`). Bottles 64.1 may leave its YAML display field at `win10`; the registry is authoritative.
- DXVK 3.0.2, VKD3D-Proton 3.0.1 and D2GI 0.5.
- KDE Plasma 6.7.3 on Wayland; keyboard and mouse input.

## Default behavior

- The unconfigured files contain `home=__noinst` and
  `base=__noinst` in `TRUCK.INI`.
- The game briefly opens a small black video window and a larger renderer
  window, writes `Turite įdiegti programą` (install the program), and exits.
- The original Indeo installer can show a failed self-registration dialog even
  after it has installed and registered the required Indeo 5 decoder.
- Without D2GI, the original DirectDraw path is not suitable for a modern 4K
  Linux desktop.

## Final behavior

- The player confirmed the Lithuanian menu remains open and usable at 4K.
- D2GI detects game version 7.3, selects the active display resolution
  dynamically, uses borderless presentation, VSync and 16x anisotropic filtering,
  and applies its aspect-ratio, interface and mirror fixes.
- Indeo 5 videos use the included native `ir50_32.dll` decoder.
- No host mount, loop device or modified executable is required at launch.
- The complete game, verified source file and compatibility state are contained in the
  dedicated `kelyje-2` bottle.

## Fixes required to reach it

The complete file set contains every file needed for a maximum installation.
Versions 6.6 and 7.3 support a documented self-contained no-CD setup:
make `[INSTALL]` use the installed directory for both `home` and `source`. This
case uses relative paths for a portable bottle:

```ini
home=.
base=.
movie=.
source=.
```

D2GI 0.5 replaces the fragile DirectDraw presentation without replacing the
Lithuanian executable. Windows XP compatibility matches the working Linux recipe
for this engine. The included Indeo installer supplies the IV50 decoder used by
the four original AVI files; the setup verifies the decoder file and registry
mapping instead of trusting the installer's unreliable final dialog.

## Quick commands

Install host tools, then create the complete bottle from the verified source file:

```bash
cd /path/to/game-compat
./install-system-packages.sh kelyje2
./windows/kelyje-2/setup-bottle.sh /path/to/kelyje-2-source-file
```

Apply or repair only the compatibility settings on an existing verified install:

```bash
./windows/kelyje-2/configure-fixes.sh /path/to/kelyje-2-source-file
./windows/kelyje-2/install-d2gi.sh
```

Launch without Steam or verify without starting the game:

```bash
./windows/kelyje-2/launch.sh
./windows/kelyje-2/verify-install.sh
```

Roll back D2GI after closing the game. The command warns before changing files;
`--yes` skips that confirmation:

```bash
./windows/kelyje-2/rollback-d2gi.sh
```

Add or update the native Steam shortcut. This warns before gracefully closing
Steam, backs up its shortcut database, verifies the new entry and restarts Steam.
Use `--yes` only when deliberately allowing the temporary Steam shutdown:

```bash
./windows/kelyje-2/setup-steam.sh
```

Leave Steam Play disabled for this shortcut: `launch.sh` starts the
Bottles-managed Windows process itself.

## Steam launch options

This is a non-Steam Windows game, so there is no `%command%` replacement line.
The non-Steam shortcut target is the repository script itself:

```text
/path/to/game-compat/windows/kelyje-2/launch.sh
```

No additional launch options are required.

## Notes for research

- Independent source-file copies were compared file by file and contained
  identical game data. The published setup accepts only the tested checksum.
- The first portable-copy baseline exited because `TRUCK.INI` deliberately
  marked its `home` and `base` as `__noinst`. This was the game's
  installation-state guard.
- The no-CD result uses the game's own path configuration and `DISK1`; it does
  not replace or modify `RigNRoll.exe`.
- Host-wide mounting was tested and rejected. It was unnecessary and has been
  removed from the launcher and package requirements.
- Windows XP mode is supported by the current Linux community recipe. Windows
  98 mode was not needed and was not tested.
- D2GI's log objectively confirmed version 7.3 detection and successful hook
  initialization before the player confirmed the stable menu.
- Modern Patch 1.05 supports some fixes on 6.6–7.3, but its modified resource
  bundle targets 8.x/1.x and was not applied over the Lithuanian data.
- Controller support was explicitly outside this case's scope.

## TODO (not yet fixed)

- Confirm one normal launch from the generated Steam shortcut.
- Confirm all four Indeo cutscenes during normal play without turning this into
  an automated gameplay test.
