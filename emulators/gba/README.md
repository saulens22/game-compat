# Game Boy Advance (GBA)

Current documented title: **Pokemon Radical Red 4.1**, patched locally from a
local Pokemon FireRed 1.0 USA file and launched with mGBA through the Steam
release of RetroArch. Additional GBA titles should be added as sections and
descriptively named helpers in this folder, not as subdirectories.

## Tested with

- Parent frontend: RetroArch Steam App ID `1118310`; see its catalog page.
- Core: current official Libretro mGBA nightly managed under
  `$EMULATION_ROOT/cores`.
- Patch: official Radical Red `4.1.zip` from `patch.radicalred.net`.
- Linux environment: see the shared tested-environment page.

## Default behavior

- Radical Red is distributed as a patch, not as a complete legal ROM.
- RetroArch cannot launch the UPS patch file directly.
- An arbitrary FireRed dump or an already patched older Radical Red ROM is not
  a valid source for the 4.1 patch.

## Final behavior

- A local script verifies the exact clean FireRed source before patching.
- The official patch archive is downloaded and checked against its pinned
  SHA-256; UPS source, patch, and output CRCs are also checked.
- A new `Pokemon - Radical Red 4.1.gba` is created without modifying the input
  source ROM.
- The verified output launches through Steam RetroArch and mGBA, preserving
  Steam Input and Overlay support.
- The confirmed Xbox layout maps A/B to GBA A/B, X/Y to Select/Start, Menu to
  the RetroArch menu, LB/RB to GBA L/R, LT to rewind, and RT to immediate 4x
  fast-forward with audible accelerated audio. Both D-pad and left stick move.

## Fixes required to reach it

1. Complete the documented RetroArch Steam setup and managed mGBA installation.
2. Supply a clean FireRed 1.0 USA input file.
3. Run the local patcher; it rejects any source whose MD5 and SHA-1 do not match
   the required revision.
4. Launch the separate patched output through the provided Steam wrapper.

No script downloads a FireRed ROM or any other copyrighted Nintendo content.

## Quick commands

Pass the path to your own clean dump:

```bash
./emulators/gba/setup-steam.sh "/path/to/Pokemon - Fire Red.gba"
./emulators/gba/launch-steam.sh
```

Read-only verification:

```bash
./emulators/gba/verify-install.sh
```

## Steam launch options

This game uses the parent RetroArch App ID and its complete launch options:

```text
PRESSURE_VESSEL_FILESYSTEMS_RW="/path/to/emulation-data" %command%
```

The wrapper passes `-L $EMULATION_ROOT/cores/mgba_libretro.so` and the patched
ROM path to Steam's RetroArch launch.

## Notes for research

- Required source size: `16777216` bytes.
- Required source MD5: `e26ee0d44e809351c8ce2d73c7400cdd`.
- Required source SHA-1: `41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc`.
- Pinned official patch ZIP SHA-256:
  `0413e4c4072fe03e909c65d737d94ef1bb30b91ef8c1b673c5b3e8c22e85102a`.
- Verified output CRC32: `fba55dd8`.
- Verified output SHA-256:
  `679d112cdfe699c2793d82c7e7999ac9dfca9e222ad5a85d4f8f1e457cd0283f`.
- Older Radical Red saves are kept separate by the new ROM filename. Save
  compatibility across hack versions is not assumed.

## TODO (not yet fixed)

- Record recommended per-game mGBA video, latency, and RTC options only after
  testing rather than applying speculative overrides.
