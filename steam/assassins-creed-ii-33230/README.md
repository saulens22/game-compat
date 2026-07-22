# Assassin's Creed II

Steam App ID `33230`. This setup fixes modern Xbox controller handling and adds
the stable high-resolution improvements from EaglePatch.

## Tested with

- Environment: [shared tested environment](../../TESTED_ENVIRONMENT.md).
- Steam edition, build `1843459`; live executable `AssassinsCreedIIGame.exe`, SHA-256 `a4ba454b0e2a9190a42db631574b694cc0dbdcec750106c1b0364b70a6e4d17e`.
- `Proton-GE Latest`, resolving to `GE-Proton11-1`, with DXVK and the current Ubisoft Connect bootstrap.
- KDE Wayland and normal Steam; Big Picture Mode was not used.
- Xbox Wireless Controller through the unchanged default Steam Input layout.
- 3840x2160, all native quality categories at maximum, 8x MSAA, VSync 60, and NVIDIA driver `610.43.03`.

## Default behavior

- Steam's first run installs legacy DirectX/XAudio prerequisites and GE-Proton
  installs Ubisoft Connect. This can take about a minute before the game appears.
- The stock game launches successfully at 4K/60 through DXVK.
- Its old input layer is known to lose modern Xbox trigger input and uses generic
  controller symbols rather than clear A/B/X/Y prompts.
- Native graphics defaulted to maximum environment, texture, shadow, reflection,
  character, and Post FX quality, but multisampling was disabled.

## Final behavior

- The real `AssassinsCreedIIGame.exe` loads Ultimate ASI Loader v4.68 and
  EaglePatchAC2 v1.1 directly from the game directory.
- EaglePatch provides XInput triggers, hotplugging, simultaneous input, 4096
  shadow maps, and restored UPlay bonus items.
- The tested 3840x2160 maximum-quality profile enables 8x MSAA and remains at 60
  FPS during the title and intro path.
- `ImproveDrawDistance=0` is deliberate: enabling it is tied to a reproducible
  crash on the first return to Florence. Stable story progression takes priority
  over that one unsafe distance override.

Hands-on acceptance of controller feel and a story-area shadow check are still
pending. The executable, renderer, plugin modules, configuration, and frame rate
have been verified automatically.

## Fixes required to reach it

The primary fix is [EaglePatch](https://github.com/Sergeanur/EaglePatch) loaded
through [Ultimate ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader).
It fixes the game engine's XInput path rather than turning gamepad input into
keyboard presses, so analog movement, triggers, rumble, and Steam's normal
controller route remain available.

The optional [Xbox Controller Prompts (AC2)](https://www.nexusmods.com/assassinscreedii/mods/178)
pack replaces generic PC icons in menus, tutorials, and the HUD. It requires an
authenticated Nexus download and its author forbids redistribution. The packed
version replaces many `.forge` archives, so it is recommended only with verified
backups; the automated setup does not pretend it is installed.

## Quick commands

Install the required host tools and complete setup:

```bash
cd /path/to/game-compat
./install-system-packages.sh ac2
# Exit Steam before the next command.
./steam/assassins-creed-ii-33230/setup-steam.sh
```

Verify without changing the installation:

```bash
cd /path/to/game-compat
./steam/assassins-creed-ii-33230/verify-install.sh
```

Restore the files, graphics configuration, and previous Steam launch options:

```bash
cd /path/to/game-compat
./steam/assassins-creed-ii-33230/rollback-fixes.sh
```

Rollback asks before changing anything. Use `--yes` only for deliberate
non-interactive rollback. These scripts never kill Steam or the game; they stop
with a warning and ask the player to exit them.

## Steam launch options

The setup writes this complete replacement line:

```text
WINEDLLOVERRIDES="dinput8=n,b" %command%
```

## Notes for research

- The installer pins EaglePatch v1.1 and Ultimate ASI Loader v4.68 with release
  checksums, and refuses an untested game executable.
- The exact Steam launch first opens Ubisoft Connect, then starts the game with
  `-uplay_steam_mode`. The launcher remaining open is not treated as success.
- `PS3Controls=0` selects the Xbox trigger/bumper arrangement.
- `SkipIntroVideos=0` preserves the original videos.
- Community reports associate 4096 shadows plus multisampling with flicker on
  some Mesa/Steam Deck configurations. The tested NVIDIA/DXVK title path showed
  no immediate failure, but a representative outdoor scene still needs review.
- No community Steam Input layout was selected or installed.

## TODO (not yet fixed)

- Player acceptance test for controller feel, trigger actions, and vibration.
- Verify 8x MSAA and 4096 shadows in Florence gameplay rather than only startup.
- Install and verify the authenticated Xbox prompt pack after the player
  downloads it from Nexus; its numerous `.forge` files require exact backups.
