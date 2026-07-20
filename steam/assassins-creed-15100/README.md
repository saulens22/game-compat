# Assassin's Creed: Director's Cut Edition

Steam App ID `15100`. This setup modernizes controller handling, removes the
bundled motion blur, restores high-resolution antialiasing, and prevents the old
engine from running hundreds of frames per second.

## Tested with

- Environment: [shared tested environment](../../TESTED_ENVIRONMENT.md), snapshot dated 2026-07-20.
- Steam Director's Cut edition, build `252091`; live executable `AssassinsCreed_Dx10.exe`.
- Exact supported DX10 MD5 `ca87753255e2d14b1f18bb737c643792` and DX9 MD5 `8e72c3333743780e43bc2c34bbf625f9`.
- `Proton-GE Latest`, resolving to `GE-Proton11-1`.
- KDE Wayland, normal Steam client, and an Xbox Wireless Controller through the unchanged default Steam Input layout.
- 3840x2160, native maximum quality values, 4x MSAA, and NVIDIA driver `610.43.03`.

## Default behavior

- The game launches, but its legacy DirectInput path labels controls as generic
  `Button 1`, `Button 2`, and so on. Modern Xbox triggers are unreliable and the
  stock high-profile action is not arranged like the later console games.
- At high resolution the menu disables multisampling even though the hardware
  can render it.
- `Post FX` includes the conspicuous motion blur rather than offering a separate
  blur toggle.
- With VSync off, the tested DX10 path ran around 244 FPS and fully loaded the
  GPU. `DXVK_FRAME_RATE=60` did nothing because this executable used
  WineD3D/OpenGL, not DXVK.

## Final behavior

- EaglePatchAC1 v1.1 supplies a fixed Xbox/XInput layout, working triggers,
  hotplugging, and simultaneous controller plus keyboard/mouse input.
- The game remains at 3840x2160 with maximum native quality values and 4x MSAA.
- Motion blur is removed by setting `PostFX=0`. This also removes depth of field
  and other effects bundled into Ubisoft's single Post FX switch.
- A hidden 32-bit MangoHud hook caps WineD3D/OpenGL at 60 FPS independently of
  the currently attached display. A live capture confirmed 60 instead of 244.
- The actual process loaded both the native ASI loader and
  `scripts/EaglePatchAC1.asi`; selecting a mod in a menu was not treated as proof.

Hands-on acceptance of the final controller feel is still pending. EaglePatch's
runtime XInput path is verified, but automated inspection cannot judge stick
sensitivity or player preference.

## Fixes required to reach it

The primary fix is [EaglePatch](https://github.com/Sergeanur/EaglePatch) with
[Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader).
EaglePatch is recommended because it fixes the actual input layer instead of
mapping controller buttons to keyboard keys. It also unlocks high-resolution
multisampling and removes the game's obsolete telemetry path.

MangoHud is used only as an invisible fixed-rate limiter. The DX10 executable
loads WineD3D/OpenGL on the tested Proton build, which is why the simpler DXVK
environment limiter failed. Both 64-bit and 32-bit MangoHud packages are listed;
the game itself is 32-bit.

For Xbox letter glyphs rather than AC1's body-part/action symbols, the optional
[Xbox Controller Prompts (AC1)](https://www.nexusmods.com/assassinscreed/mods/106)
pack is recommended. Nexus requires an authenticated download and prohibits
redistribution, so the setup does not silently replace the 168 MB `DataPC.forge`.
Use its `Upscaled - Packed` version only after backing up the original forge.

## Quick commands

Install the required host tools and complete setup:

```bash
cd /path/to/game-compat
./install-system-packages.sh ac1
# Exit Steam before the next command.
./steam/assassins-creed-15100/setup-steam.sh
```

Verify without changing the installation:

```bash
cd /path/to/game-compat
./steam/assassins-creed-15100/verify-install.sh
```

Restore the files, graphics configuration, and previous Steam launch options:

```bash
cd /path/to/game-compat
./steam/assassins-creed-15100/rollback-fixes.sh
```

Rollback asks before changing anything. Use `--yes` only for deliberate
non-interactive rollback. These scripts never kill Steam or the game; they stop
with a warning and ask the player to exit them.

## Steam launch options

The setup writes this complete replacement line:

```text
WINEDLLOVERRIDES="dinput8=n,b" MANGOHUD_CONFIG="fps_limit=60,no_display" mangohud --dlsym %command%
```

## Notes for research

- The installer pins EaglePatch v1.1, Ultimate ASI Loader v4.68, their release
  archive checksums, and both supported executable hashes.
- `PS3Controls=0` intentionally keeps the Xbox-style trigger/bumper order.
- `SkipIntroVideos=0` preserves the original introductions.
- The game can drop to a decorated window when it loses focus under Wayland.
  Its saved `Fullscreen=1` value is retained; normal Steam launch keeps focus.
- A previous attempt to capture the game with Alt-Tab disturbed fullscreen, so
  later evidence used direct KWin window targeting.
- No Workshop/community Steam Input layout was selected or installed.

## TODO (not yet fixed)

- Player acceptance test for the patched controller feel and stick sensitivity.
- Install and verify the authenticated upscaled Xbox prompt pack after the
  player downloads it from Nexus.
