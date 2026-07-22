# Nintendo Switch emulation

This guide uses the standalone native Linux Ryujinx build. RetroArch has no
recommended Switch core, so forcing this system through RetroArch would reduce
compatibility without improving Steam integration.

## Tested with

- Shared computer and Linux packages: [tested environment](../../TESTED_ENVIRONMENT.md).
- Ryujinx 1.3.3 on Linux with Vulkan and Nintendo Switch firmware 19.0.0.
- NVIDIA GeForce RTX 4060 Laptop GPU with driver 610.43.03.
- Pokémon Violet base game 1.0.0 booted through the direct Ryujinx path.
- Pokémon Scarlet base game 1.0.0 was recognized; a full boot test is pending.
- Xbox-style Pro Controller mapping through Ryujinx's input layer.
- Steam shortcuts are prepared but were not yet tested.

## Default behavior

Ryujinx opens in its normal window and a title must be selected from its shared
library. Resolution scaling and input use the current global Ryujinx settings.
During the first Pokémon Violet test, Docked 3× scaling produced about 21.85 FPS
and 70–94% RTX 4060 load. Visible glitches coincided with background graphics
pipeline misses.

## Final behavior

Pokémon Violet boots with Vulkan on the NVIDIA GPU. The included launchers start
Scarlet or Violet directly and request fullscreen. They deliberately do not
force a display resolution. Performance at 2× scaling and both Steam shortcuts
remain unconfirmed.

## Fixes required to reach it

Install the native Linux Ryujinx build, then use Ryujinx's documented workflow
to import keys, firmware, games and updates from hardware you own. Keep the game
library under `$EMULATION_ROOT/roms/switch/`. On a hybrid-GPU computer, select
the discrete Vulkan device in Ryujinx.

Use 2× scaling as the initial high-resolution test. Docked 3× renders at roughly
5760×3240 and was too demanding in the tested configuration. The shared
launcher changes only Ryujinx's `start_fullscreen` setting.

## Quick commands

Start either documented title directly in fullscreen:

```bash
./emulators/switch/launch-pokemon-scarlet.sh
./emulators/switch/launch-pokemon-violet.sh
```

Create or update one Steam shortcut. Each script warns and asks before closing
Steam; pass `--yes` only when deliberate:

```bash
./emulators/switch/setup-pokemon-scarlet-steam.sh
./emulators/switch/setup-pokemon-violet-steam.sh
```

## Steam launch options

No custom launch options are recommended. Leave each non-Steam shortcut's
launch options empty; the equivalent normal Steam command form is:

```text
%command%
```

## Notes for research

Scarlet and Violet share emulator requirements but retain separate game files,
saves, updates and Steam shortcuts. Nintendo has published later updates with
many fixes. Test a current update exported from the player's own console before
changing Vulkan accuracy or shader settings to address pipeline artifacts.

## TODO (not yet fixed)

- Verify a full Scarlet boot with the current firmware and NVIDIA Vulkan path.
- Retest Violet at 2× scaling and with a current game update.
- Test both Steam shortcuts, Overlay, fullscreen and controller behavior.
