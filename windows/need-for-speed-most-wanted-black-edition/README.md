# Need for Speed: Most Wanted Black Edition

This guide sets up the 2005 PC Black Edition in its own Bottles environment.
The game is installed first; the scripts then add the Linux compatibility fixes.

The canonical setup is the player-confirmed working 64-bit Bottles prefix using
GE-Proton 11-1. New installations use the same architecture and dependency path.

## Tested with

- Shared computer and Linux packages: [tested environment](../../TESTED_ENVIRONMENT.md), captured 2026-07-20.
- English Black Edition 1.3.
- `speed.exe` SHA-256: `80774c2e5d619b4f120b48d4462896fd504c263399d203a238769cffde1d253c`.
- Bottles Flatpak 64.1 with a fresh `nfsmw-black-edition` win64 bottle,
  confirmed working at 3840×2160 on 2026-07-21.
- GE-Proton 11-1, DXVK 3.0.2 and the DirectX 9 June 2010 helper files.
- ThirteenAG Widescreen Fix downloaded 2026-07-21.
- KDE Plasma 6.7.3 on Wayland.
- Keyboard and mouse. Controller support has not been tested.

## Default behavior

The tested installer includes a very old widescreen patch. On Linux its ASI
loader does not load unless Wine is told to prefer the game's `dinput8.dll`.
Without that setting, the menus remain 4:3 and the game can start at a very low
resolution. During the first test, the resolution had to be changed manually.

The original Soda 9.0-1 runner also asks for NT sync but cannot use it, so it
prints a warning and falls back to fsync.

## Final behavior

The current confirmed setup provides:

- the current Widescreen Fix instead of the obsolete included version;
- the correct resolution for whichever display is active when the game starts;
- corrected widescreen HUD and field of view;
- better shadows, high-quality audio and corrected high-frame-rate timing;
- GE-Proton 11-1 with NT sync and native DirectX 9 helper files;
- optional direct Steam integration using the same win64 prefix;
- complete Steam library artwork generated from a pinned SteamGridDB cover;
- Steam Overlay and the FPS counter when the optional Steam path is used.

The player confirmed the canonical win64 GE-Proton bottle launches and renders
at 3840×2160. Direct Steam launch, NT sync, Steam Overlay and the FPS counter
were then confirmed separately.

## Fixes required to reach it

### Current widescreen support

The setup installs the current
[ThirteenAG Widescreen Fix](https://github.com/ThirteenAG/WidescreenFixesPack/releases/tag/nfsmw).
It corrects the HUD, field of view and timing and adds modern display support.

The old `NFSMW2005_widescreen_fix.asi` is backed up and disabled. It must not be
left beside the current `NFSMostWanted.WidescreenFix.asi`; the two versions can
crash when loaded together.

Wine is configured with `dinput8=n,b` so the game's local ASI loader is used.

### Automatic resolution

The launcher asks the Widescreen Fix to use the current desktop resolution
every time the game starts. It does not assume 4K, 1080p, 16:9 or any particular
monitor, so connecting a different display does not require editing the script.

Some old menu artwork and videos may still have black bars because those assets
were made for 4:3. The rendered game itself should use the full display.

### DirectX 9 and NT sync

The game installer is not trusted to install old DirectX components correctly.
After selecting GE-Proton, the setup freshly installs the Bottles-bundled
Winetricks `d3dx9` and `d3dcompiler_47` packages. The latter is required by the
64-bit prefix's DirectX dependency chain. No dependency DLLs are copied from
another prefix.

Your kernel already provides `/dev/ntsync`, and Bottles can access it. The bottle
is configured for NT sync. Runner output reported `ntsync: up and running`, and
the player then confirmed the game launch using that configuration.

### Optional HD upgrades

These are available but are not installed yet:

- [Xbox 360 Stuff Pack 4.1](https://nfsmods.xyz/mod/1200) is the preferred
  original-style graphics upgrade. It adds the Xbox 360 shaders, higher-quality
  world textures, sky, lighting, effects and audio.
- [NFS HD Reflections](https://github.com/AeroWidescreen/NFSHDReflections)
  improves vehicle, road and mirror reflections. It is designed to work with
  the Widescreen Fix and Xbox 360 Stuff Pack.
- [Most Wanted HQ 1.20.9](https://www.moddb.com/mods/most-wanted-hq) is a much
  larger overhaul. It changes cars, lighting and game data and may require a
  clean profile, so it will remain a separate optional setup.

The Xbox 360 pack and HD Reflections will be added after their current downloads,
checksums, install order and rollback have been tested. This prevents an HD pack
from breaking the working base setup.

### Steam artwork

The Steam setup downloads one selected
[SteamGridDB cover](https://www.steamgriddb.com/game/5258915), verifies its
checksum, and generates the portrait, horizontal grid, hero, logo and icon sizes
Steam expects. This avoids an empty grey non-Steam shortcut and keeps the setup
repeatable. The generated images contain no machine-specific information.

### Optional Steam integration

The ordinary Bottles Flatpak wrapper works without Steam, but cannot display
Steam Overlay because of [Valve issue #8952](https://github.com/ValveSoftware/steam-for-linux/issues/8952).
If Steam features are wanted, `setup-steam.sh` instead creates one direct
Windows shortcut, pins Proton-GE Latest and lets Steam Proton share the canonical
win64 Bottles prefix. The player confirmed the game, Overlay and FPS counter.

This shared-prefix method is useful but brittle because both Bottles and Steam
Proton can update prefix metadata. Snapshot the bottle before changing either
runner. The Steam helper also resets the Widescreen Fix resolution sentinel
before every launch so changing monitors does not retain an obsolete resolution.

## Quick commands

### 1. Create the bottle

This creates a win64 bottle directly. Do not create a win32 bottle first; no
migration or conversion step is part of this guide.

```bash
cd /path/to/game-compat
./install-system-packages.sh nfsmw
./windows/need-for-speed-most-wanted-black-edition/setup-bottle.sh
```

### 2. Install the game

Open the `nfsmw-black-edition` bottle in Bottles.

1. Copy the complete installation files into
   `C:\\Install\\NFSMW-Black-Edition` inside the bottle.
2. Run the installer from Bottles.
3. Finish the game installation.
4. Skip the installer's DirectX, Visual C++ and desktop-shortcut options. The
   setup script installs the tested dependency and Steam shortcut later.

None of the repository scripts accept or copy game installation files.

### 3. Install the Linux fixes

```bash
./windows/need-for-speed-most-wanted-black-edition/configure-fixes.sh
./windows/need-for-speed-most-wanted-black-edition/verify-install.sh
```

### 4. Launch the game

```bash
./windows/need-for-speed-most-wanted-black-edition/launch.sh
```

### 5. Optionally add it to Steam

```bash
./windows/need-for-speed-most-wanted-black-edition/setup-steam.sh
```

Skip this step if you do not want Steam integration. The command warns before
closing Steam, removes obsolete NFSMW/test entries so one shortcut remains,
backs up Steam's database, adds complete artwork, pins Proton-GE Latest and
restarts Steam normally. It does not start Big Picture Mode.

### Restore the old widescreen files

Close the game first, then run:

```bash
./windows/need-for-speed-most-wanted-black-edition/rollback-widescreen-fix.sh
```

Use `--yes` only when intentionally skipping the confirmation prompt.

## Steam launch options

The optional direct shortcut uses this complete launch-options line. The setup
script expands both paths for the current user:

```bash
"/path/to/game-compat/windows/need-for-speed-most-wanted-black-edition/prepare-steam-launch.sh" && STEAM_COMPAT_DATA_PATH="$HOME/.local/share/game-compat/steam-compat/nfsmw-black-edition" %command%
```

Users who do not want Steam should launch `launch.sh`; Steam is not required for
the confirmed Bottles setup.

## Notes for research

- Version 1.3 is the final official game patch.
- The game launched with Soda 9.0-1 before the runner change, but it initially
  used a tiny resolution. The player selected 3840x2160 manually.
- The current Widescreen Fix did not load until the bottle received the
  `dinput8=n,b` setting.
- The first switch to GE-Proton failed because the bottle still contained a
  Soda version of `d3dx9_26.dll`.
- Repeating the change one step at a time and installing Winetricks `d3dx9`
  replaced it with the native 32-bit DirectX file.
- Wine 11.13 was also tested and rejected because it fell back to fsync and
  produced additional Wine/EGL errors.
- No controller layout, save editing or automated gameplay was tested.
- Steam's shortcut had `AllowOverlay=1` and the global FPS counter was enabled.
- Forwarding Steam's current `steamrt32/gameoverlayrenderer.so`, `SteamAppId`,
  `SteamGameId`, and `SteamOverlayGameId` was verified inside `speed.exe`, but
  the player confirmed the overlay and Steam FPS counter still did not appear.
- This reproduces Valve's open Flatpak non-Steam overlay issue. The ineffective
  environment workaround was removed rather than published as a fix.
- An early research-only direct Steam-Proton experiment used a pure win32
  prefix. Proton rejected that architecture before game startup. This failed
  experiment is not part of the installation procedure.
- The published setup starts directly with a fresh win64 bottle and installs
  its dependencies through Winetricks. The player confirmed that this
  GE-Proton Bottles baseline works at 3840×2160. Migration from win32 is neither
  required nor supported by these scripts.
- Direct Steam Proton sharing of the canonical win64 prefix was then tested.
  The live `speed.exe` used GE-Proton 11-1, the expected shared prefix and the
  NVIDIA renderer; both Steam overlay libraries were mapped. The player
  confirmed the game, Shift+Tab Overlay and Steam's FPS counter.

## TODO (not yet fixed)

- Open Video settings and confirm the active display resolution is selected
  without changing it manually.
- After the base setup works, install and test Xbox 360 Stuff Pack 4.1 with HD
  Reflections as a reversible HD option.

## Game links

- [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Need_for_Speed%3A_Most_Wanted)

## Fix and project links

- [ThirteenAG Widescreen Fix](https://github.com/ThirteenAG/WidescreenFixesPack/releases/tag/nfsmw)
- [Xbox 360 Stuff Pack 4.1](https://nfsmods.xyz/mod/1200)
- [NFS HD Reflections](https://github.com/AeroWidescreen/NFSHDReflections)
- [Most Wanted HQ](https://www.moddb.com/mods/most-wanted-hq)
