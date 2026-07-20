# Assassin's Creed Brotherhood

Steam App ID `48190`. This profile provides native Xbox controller input,
maximum graphics without motion blur, and a reliable 60 FPS safety cap.

## Tested with

- Environment: [shared tested environment](../../TESTED_ENVIRONMENT.md), snapshot dated 2026-07-20.
- Steam edition; live executable `ACBSP.exe` through DXVK D3D9.
- Proton Experimental; GE-Proton11-1 was also tested and rejected for this build.
- KDE Wayland and normal Steam; Big Picture Mode was not assumed.
- Xbox Wireless Controller through the unchanged default Steam Input layout.
- 3840x2160, maximum native quality, 8x MSAA, PostFX off, and NVIDIA driver `610.43.03`.

## Default behavior

- The first Steam launch installs legacy prerequisites and Ubisoft Connect.
- The game may fail during hardware initialization, and the stock input path can
  select keyboard/mouse even with an Xbox controller attached.
- The title runs far above 60 FPS when uncapped. Brotherhood has mission,
  cutscene, and vehicle-control faults at excessive frame rates.
- Ubisoft Connect may remain headless after a normal game exit, leaving Steam
  showing the game as running.

## Final behavior

- Proton Experimental launches the real `ACBSP.exe` through DXVK.
- The game identifies `Controller (XBOX 360 For Windows)`, displays Xbox prompts,
  and uses native analog/XInput behavior. The player confirmed the controls feel
  correct.
- Graphics use every native quality maximum and 8x MSAA. PostFX is disabled to
  remove the strong motion blur and bloom.
- A hidden MangoHud limiter holds the game at 60 FPS without adding an overlay.
- Resolution and refresh rate are left under the player's control, so changing
  displays does not require rerunning a resolution-specific script.

## Fixes required to reach it

`PROTON_PREFER_SDL=1` selects Proton's SDL-backed controller route; this was the
single change that made Brotherhood expose its native Xbox 360 input profile.
It does not install or select a community Steam Input layout.

[MangoHud](https://github.com/flightlessmango/MangoHud) is used only as a hidden
60 FPS limiter. The simpler `DXVK_FRAME_RATE=60` setting was tested but the live
title screen still ran near 159 FPS, so it was rejected. The cap prevents known
high-frame-rate mission and control failures while leaving VSync independent of
the current display.

The setup also creates the legacy `SAVES` directory. Before it existed, startup
was unreliable; afterward the game created its `OPTIONS` data normally.

## Quick commands

Install the host dependency and apply the complete profile:

```bash
cd /path/to/game-compat
./install-system-packages.sh brotherhood
# Exit Steam before the next command.
./steam/assassins-creed-brotherhood-48190/setup-steam.sh
```

Verify without changing the installation:

```bash
./steam/assassins-creed-brotherhood-48190/verify-install.sh
```

Restore the original game configuration and previous Steam launch options:

```bash
./steam/assassins-creed-brotherhood-48190/rollback-fixes.sh
```

Rollback asks for confirmation. `--yes` is available for deliberate
non-interactive use. These scripts never kill Steam or the game; they stop and
ask the player to exit them.

## Steam launch options

The setup writes this complete replacement line:

```text
PROTON_PREFER_SDL=1 MANGOHUD_CONFIG=fps_limit=60,no_display mangohud %command%
```

## Notes for research

- GE-Proton11-1 reached DXVK D3D9 but reproducibly hit an execute-access fault
  during hardware initialization. Limiting CPU affinity to cores 0-7 did not help.
- Proton Experimental plus the SDL input route passed live startup and native
  controller testing.
- The 60 FPS MangoHud result was verified live; this is a compatibility cap, not
  a response to weak hardware.
- Ubisoft's legacy-login dialog may ask for the account password again even
  though its logs show successful Steam-ticket login and remembered account data.
- A normal in-game exit closed `ACBSP.exe`, but the headless launcher persisted
  and held the Steam session open. The tray bridge exposed only a 0.5-pixel Wine
  helper and ignored standard close requests.
- No community controller layout or game mod is installed.

### Game links

- [Steam store](https://store.steampowered.com/app/48190/)
- [Steam Community](https://steamcommunity.com/app/48190)
- [ProtonDB](https://www.protondb.com/app/48190)
- [SteamDB](https://steamdb.info/app/48190/)

### Fix and project links

- [Proton](https://github.com/ValveSoftware/Proton)
- [MangoHud](https://github.com/flightlessmango/MangoHud)

## TODO (not yet fixed)

- Confirm whether manually choosing Quit on Ubisoft Connect's tray icon ends its
  headless post-game session cleanly.
- Test whether Ubisoft's password re-entry prompt returns after that fully clean
  launcher exit; credentials are intentionally never automated or stored.
- Complete a representative story mission to validate the profile beyond menus
  and initial gameplay.
