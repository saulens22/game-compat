# Kelyje II

Lithuanian version 7.3 of *Hard Truck 2*, running on Linux in one
isolated Bottles bottle. Controller support was intentionally not investigated.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md).
- `RigNRoll.exe` version 7.3 dated 2001, SHA-256 `b7deb5fca7c4f2ab0eb8e02c3aae441eed13e3c4bb53797afd2df35f0721cc28`.
- Bottles Flatpak 64.1, dedicated win64 `kelyje-2` gaming bottle and GE-Proton
  11-1 runner.
- Wine compatibility identity: Windows XP (`CurrentVersion 5.1`). Bottles 64.1 may leave its YAML display field at `win10`; the registry is authoritative.
- DXVK 3.0.2, VKD3D-Proton 3.0.1 and D2GI 0.5.
- KDE Plasma 6.7.3 on Wayland; keyboard and mouse input.

## Default behavior

- The unconfigured files contain `home=__noinst` and
  `base=__noinst` in `TRUCK.INI`.
- The game briefly opens a small black video window and a larger renderer
  window, writes `Turite įdiegti programą` (install the program), and exits.
- The original Indeo installer can show a failed self-registration dialog.
  The reproducible setup therefore installs the `icodecs` Winetricks dependency
  itself and verifies the resulting decoder and registry mapping.
- Without D2GI, the original DirectDraw path is not suitable for a modern 4K
  Linux desktop.

## Final behavior

- The player confirmed the Lithuanian menu remains open and usable at 4K.
- D2GI detects game version 7.3, selects the active display resolution
  dynamically, uses borderless presentation, VSync and 16x anisotropic filtering,
  and applies its aspect-ratio, interface and mirror fixes.
- Ligos Indeo 5.11 is installed and registered, but the introductory video
  still does not play in the win64 setup. The player accepted this limitation.
- No host mount, loop device or modified executable is required at launch.
- The complete installed game and compatibility state are contained in the
  dedicated `kelyje-2` bottle.
- Optional direct Steam integration preserves D2GI widescreen support and was
  player-confirmed with Steam Overlay and the FPS counter.

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
for this engine. [Wine bug 54670](https://bugs.winehq.org/show_bug.cgi?id=54670),
covering 16-bit installers under new WoW64, was fixed in Wine 10.16. Winetricks
still conservatively blocks `icodecs`, so
the setup uses its documented `--force` path under GE-Proton 11 and verifies
the result. Winetricks' silent path leaves Indeo 5.07 active; the bundled,
checksum-identical Ligos installer must then be completed interactively to
install 5.11. Its optional DirectShow component can report an error while the
required VfW decoder still installs successfully.

## Quick commands

Install host tools and create the empty dedicated bottle:

```bash
cd /path/to/game-compat
./install-system-packages.sh kelyje2
./bottles-game.sh ensure kelyje-2 win64 gaming
```

Copy your installation files into `C:\\Install\\Kelyje2` inside that bottle.
Run the installer through Bottles and choose a complete installation at
`C:\\Games\\Kelyje2`. Its codec step can report a DirectShow error, so do not
treat it as proof that video support is ready. Only after the game installation
is complete, run the verified dependency and fix setup:

```bash
./windows/kelyje-2/setup-bottle.sh
```

Apply or repair only the compatibility settings on an existing verified install:

```bash
./windows/kelyje-2/configure-fixes.sh
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

Steam integration is optional. Add or update it only if you want Steam Overlay,
the FPS counter or library launching. This warns before gracefully closing
Steam, replaces obsolete Kelyje shortcuts so only one remains, installs complete
artwork, pins Proton-GE Latest, verifies the entry and restarts Steam normally.
Use `--yes` only when deliberately allowing the temporary Steam shutdown:

```bash
./windows/kelyje-2/setup-steam.sh
```

This direct path lets Steam Proton and Bottles share one win64 prefix. It is
convenient but brittle: either tool may update prefix metadata. Snapshot the
bottle before changing the Bottles runner or Steam compatibility tool.
The shortcut artwork comes from the official Steam assets for the same
underlying *Hard Truck 2: King of the Road* game and is downloaded with pinned
checksums. The installed Lithuanian 7.3 edition remains unchanged.

## Steam launch options

The optional direct Steam shortcut uses this complete launch-options line. The
setup script expands the per-user state path automatically:

```bash
WINEDLLOVERRIDES="ddraw=n,b;ir50_32=n,b" STEAM_COMPAT_DATA_PATH="$HOME/.local/share/game-compat/steam-compat/kelyje-2" %command%
```

`ddraw=n,b` is essential: without it Steam loads Proton's built-in DirectDraw
instead of D2GI, so widescreen support disappears. `ir50_32=n,b` retains the
native Indeo preference. Users who do not want Steam should continue using
`launch.sh`; Steam is not required for the working Bottles setup.

## Notes for research

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
- The win64 baseline reached the menu, but neither Winetricks Indeo
  5.07 nor interactively installed Ligos Indeo 5.11 restored the intro. The
  player accepted the missing intro rather than retaining a win32 prefix.
- The first direct Steam run loaded Proton's built-in `ddraw.dll`, so the game
  lost widescreen support. Adding `ddraw=n,b;ir50_32=n,b` loaded the local D2GI
  wrapper; its log confirmed the 3840x2160 mode and aspect-ratio hooks, and the
  player confirmed widescreen plus Steam Overlay.
- Command-line diagnostics must use the shortcut's full 64-bit game ID. Steam
  `-applaunch` misread the high unsigned shortcut App ID as an unrelated store
  app and displayed a bad-configuration error; launching from the library was
  not affected.
- Modern Patch 1.05 supports some fixes on 6.6–7.3, but its modified resource
  bundle targets 8.x/1.x and was not applied over the Lithuanian data.
- Controller support was explicitly outside this case's scope.

## TODO (not yet fixed)

- Confirm all four Indeo cutscenes during normal play without turning this into
  an automated gameplay test.
- Restore the introductory video in the win64 setup, if a decoder path is found
  that does not compromise the confirmed game, D2GI or Steam behavior.

## Game links

- [Hard Truck 2: King of the Road on Steam](https://store.steampowered.com/app/4487840/Hard_Truck_2_King_of_the_Road/) — related current release; it is not the tested Lithuanian 7.3 build.
- [Hard Truck 2: King of the Road on GOG](https://www.gog.com/en/game/hard_truck_2_king_of_the_road) — related modern release, not the tested build.
- [Internet Archive: Hard Truck 2 / Kelyje II](https://archive.org/details/Kelyje_2) — historical metadata, cover art, version information and links to community compatibility guidance for the Lithuanian release.
- [Archived Akelotė ir Ko publisher page](https://web.archive.org/web/20020402185337/http://www.akeloteirko.lt/zaidimai_view.php?id=316) — period publisher information preserved by the Wayback Machine.

## Fix and project links

- [D2GI releases](https://github.com/REDPOWAR/D2GI/releases) — the tested DirectDraw replacement; version 0.5 is installed by this case's pinned setup script.
- [D2GI modern-systems guide](https://www.moddb.com/games/hard-truck-2/tutorials/how-to-run-hard-truck-2-on-modern-systems) — community installation and configuration background linked by the Archive item.
- [PCGamingWiki: Hard Truck 2](https://www.pcgamingwiki.com/wiki/Hard_Truck_2) — overview of D2GI, widescreen support and known compatibility issues.
- [King of the Road Modern Patch](https://www.moddb.com/games/hard-truck-2/downloads/king-of-the-road-modern-patch) — researched but not installed: its mixed-version resource changes were not applied over the confirmed Lithuanian 7.3 data.
- [Lithuanian localization for version 8.1](https://www.moddb.com/games/hard-truck-2/downloads/lithuanian-localization-for-81-with-mods) — an alternative edition referenced by the Archive item, not part of this tested 7.3 setup.
