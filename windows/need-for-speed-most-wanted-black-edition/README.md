# Need for Speed: Most Wanted Black Edition

This guide sets up the 2005 PC Black Edition in its own Bottles environment.
The game is installed first; the scripts then add the Linux compatibility fixes.

The canonical setup is the player-confirmed working 64-bit Bottles prefix using
GE-Proton 11-1. New installations use the same architecture and dependency path.

## Tested with

- Shared computer and Linux packages: [tested environment](../../TESTED_ENVIRONMENT.md).
- English Black Edition 1.3.
- `speed.exe` SHA-256: `80774c2e5d619b4f120b48d4462896fd504c263399d203a238769cffde1d253c`.
- Bottles Flatpak 64.1 with a fresh `nfsmw-black-edition` win64 bottle,
  confirmed working at 3840×2160.
- GE-Proton 11-1, DXVK 3.0.2 and the DirectX 9 June 2010 helper files.
- ThirteenAG Widescreen Fix.
- KDE Plasma 6.7.3 on Wayland.
- Keyboard and mouse plus an Xbox controller through Steam Input and the
  Widescreen Fix's XInput support. The player manually remapped the controls to
  a preferred modern layout.
- Xbox 360 Stuff Pack 4.1 Easy Installation and NFS HD Reflections,
  player-confirmed.

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
- Xbox 360 shaders, lighting, world textures, effects and higher-quality audio;
- display-sized HD vehicle, road, water and mirror reflections;
- working Xbox controller input through the existing Widescreen Fix path.

The player confirmed the canonical win64 GE-Proton bottle launches and renders
at 3840×2160. Direct Steam launch, NT sync, Steam Overlay and the FPS counter
were then confirmed separately.

The original Steam pre-launch helper used Bottles' registry command. In live
use, that command left Wine service processes behind after `speed.exe` exited,
so Steam kept the shortcut marked **Running**. Version 9 replaces it with a
locked offline `user.reg` edit and adds a ten-second preparation timeout.

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

The resolution sentinel is written with the shared offline registry helper.
It refuses to edit a running prefix, creates `user.reg.game-compat.bak`, and
does not start Wine services that could outlive the game.

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

### Optional Xbox 360 visual and audio upgrade

[Xbox 360 Stuff Pack 4.1](https://nfsmods.xyz/mod/1200) is the confirmed
original-style upgrade. It adds the Xbox 360 shaders, lighting, world textures,
effects, PC bug fixes and higher-quality soundtrack. Use its **Easy
Installation** archive on Linux: the Complex installer depends on NFS-VltEd,
whose protected .NET executable failed before opening under GE-Proton, Soda and
native Mono during this research.

[NFS HD Reflections](https://github.com/AeroWidescreen/NFSHDReflections) is
installed after Xbox 360 Stuff. `AutoRes=1` keeps reflection sizes tied to the
active display. Xbox 360 Stuff requires `CubemapBrightnessFix=0` and
`RestoreWaterReflections=1`.

The pack also requires `FixHUD=0`, `Scaling=0` and `FMVWidescreenMode=0` in the
current Widescreen Fix. Keep `WriteSettingsToFile=0`: enabling it generated
`g_RacingResolution=1`, which made the game render in a small corner with
glitching around it. The normal launcher continues resetting the registry to
the automatic-resolution sentinel before every start.

[Most Wanted HQ](https://www.moddb.com/mods/most-wanted-hq) is a separate,
incompatible overhaul that expects a clean game and new profile. Do not layer
it over this setup.

### Xbox controller

The current Widescreen Fix's `ImproveGamepadSupport=1` path worked with an Xbox
controller through Steam. The player remapped the controls in game to a more
modern personal layout. XtendedInput and the separate Original Button Pack were
researched but not installed because replacing a confirmed working input path
would risk changing that mapping.

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

The pre-launch step is intentionally a short host-side file edit. It never
starts Bottles, Wine or Proton. Steam tracks the complete launch command, so a
Wine process started by this step could survive `speed.exe` and leave the game
permanently marked **Running**. The helper refuses to edit an active prefix and
Steam limits it to ten seconds.

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

### 5. Optionally install the confirmed Xbox 360 HD pack

Download the **Easy Installation** archive from Xbox 360 Stuff Pack 4.1 and the
latest NFS HD Reflections archive. Then pass those two mod archives to:

```bash
./windows/need-for-speed-most-wanted-black-edition/install-hd-pack.sh \
  "/path/to/Easy Installation.zip" \
  "/path/to/NFS HD Reflections.zip"
```

The script verifies every payload file against the tested manifests, installs
Xbox 360 Stuff first, adds HD Reflections and applies the confirmed compatible
settings. It does not accept game installation files or touch saves.

### 6. Optionally add it to Steam

```bash
./windows/need-for-speed-most-wanted-black-edition/setup-steam.sh
```

Skip this step if you do not want Steam integration. The command warns before
closing Steam, removes obsolete NFSMW/test entries so one shortcut remains,
backs up Steam's database, adds complete artwork, pins Proton-GE Latest and
restarts Steam normally. It does not start Big Picture Mode.

After Steam reopens, launch **Need for Speed: Most Wanted Black Edition** from
the Library. The confirmed path starts `speed.exe` directly through Steam
Proton, attaches Steam Overlay and uses the same bottle as the normal launcher.
Exiting the game normally must clear Steam's **Running** state.

Do not run the Bottles launcher and Steam shortcut at the same time. Before
changing the Bottles runner or Steam compatibility tool, close the game and
snapshot the shared bottle:

```bash
mkdir -p "$HOME/.local/share/game-compat/snapshots"
./bottles-game.sh snapshot nfsmw-black-edition \
  "$HOME/.local/share/game-compat/snapshots/nfsmw-black-edition.tar.zst"
```

If the game has closed but Steam still shows it as running, first confirm that
`speed.exe` is absent, then stop only this bottle:

```bash
pgrep -ax speed.exe || true
./bottles-game.sh stop nfsmw-black-edition
```

The stop command warns before terminating Wine processes and asks for
confirmation. Do not kill or restart the whole Steam client as the first
recovery step.

### Restore the old widescreen files

Close the game first, then run:

```bash
./windows/need-for-speed-most-wanted-black-edition/rollback-widescreen-fix.sh
```

Use `--yes` only when intentionally skipping the confirmation prompt.

## Steam launch options

`setup-steam.sh` writes the setting automatically; users normally should not
paste or modify it. For inspection or manual recovery, this is the complete
portable replacement line. Replace `/path/to/game-compat` with the repository
location; the setup script performs that expansion itself:

```bash
timeout --foreground --signal=TERM --kill-after=2s 10s "/path/to/game-compat/windows/need-for-speed-most-wanted-black-edition/prepare-steam-launch.sh" && STEAM_COMPAT_DATA_PATH="$HOME/.local/share/game-compat/steam-compat/nfsmw-black-edition" %command%
```

Users who do not want Steam should launch `launch.sh`; Steam is not required for
the confirmed Bottles setup. Do not combine this line with old Bottles, Wine,
registry, Overlay-preload or test launch options.

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
- Xbox controller input was later player-confirmed through Steam and the
  Widescreen Fix. The player performed a manual modern-layout remap; that
  personal mapping is not imposed by the installer.
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
- The Xbox 360 Stuff Complex installer was rejected for Linux after NFS-VltEd
  failed before opening with the same .NET exception in isolated 32-bit and
  64-bit Bottles tests. The official Easy Installation payload avoided those
  Windows-only modding tools.
- The first Easy Installation run used the pack README's
  `WriteSettingsToFile=1`. It generated `g_RacingResolution=1`, producing a
  small corner image and glitched surrounding area. Keeping settings in the
  registry, while disabling only the three conflicting widescreen HUD options,
  produced the player-confirmed correct presentation.
- Xbox 360 Stuff, Xenon Effects, TexWizard, Widescreen Fix, HD Reflections and
  Steam's 32-bit Overlay library were all verified in the live `speed.exe`.
- A later session exposed a wrapper-lifetime bug: `speed.exe` had exited, but
  Bottles registry setup left `services.exe` and `winedevice.exe` alive for
  roughly fifteen hours. Steam tracked the enclosing launch shell and therefore
  kept the game marked Running. Bottle-scoped `wineboot -k` plus `SIGTERM` to
  the two stale launch roots cleared it without restarting Steam. The unsafe
  Wine-based preparation path was removed rather than merely documenting the
  recovery.
- The replacement was then tested through the actual Steam non-Steam shortcut.
  `speed.exe` remained running, Steam attached its Overlay, and
  no registry-preparation process remained. After the player exited normally,
  Steam removed every tracked process and the launch root exited with status
  zero; the shortcut no longer remained marked Running.
- Front-End Shadows was not added because Xbox 360 Stuff already supplies
  garage/shop dynamic shadows. Recompiled Vinyls, converted movies and UI Texts
  make broader data or media changes and were not needed for this confirmed
  result.

## TODO (not yet fixed)

- Test the confirmed stack on a non-16:9 display when one is available.
- If the player later wants a shareable modern controller preset, capture and
  document it separately without overwriting Steam's default layout.

## Game links

- [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Need_for_Speed%3A_Most_Wanted)

## Fix and project links

- [ThirteenAG Widescreen Fix](https://github.com/ThirteenAG/WidescreenFixesPack/releases/tag/nfsmw)
- [Xbox 360 Stuff Pack 4.1](https://nfsmods.xyz/mod/1200)
- [NFS HD Reflections](https://github.com/AeroWidescreen/NFSHDReflections)
- [Most Wanted HQ](https://www.moddb.com/mods/most-wanted-hq)
