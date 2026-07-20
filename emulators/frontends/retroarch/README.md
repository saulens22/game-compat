# RetroArch (Steam release)

Steam App ID `1118310`, using the native Linux Steam build and Steam Input.

## Tested with

- Environment: see the shared [tested environment](../../../TESTED_ENVIRONMENT.md).
- RetroArch `1.22.2`, Steam build ID `20833747`.
- Native Steam client on KDE Wayland; Big Picture was also tested but is optional.
- Controller navigation verified through Steam Input with SDL2 input.

## Default behavior

- RetroArch launches correctly through Steam with controller support.
- Steam Linux Runtime hides arbitrary host directories such as `/data`.
- Steam supplies a limited selection of cores as DLC, and its build does not
  provide the normal daily automatic core updater.
- ROMs, BIOS, saves, and states initially live in unrelated default locations.

## Final behavior

- Steam launches the native RetroArch App ID directly with Overlay and Steam
  Input intact.
- Only the configured `$EMULATION_ROOT` is added as writable external storage.
- ROMs, BIOS, saves, states, playlists, screenshots, core binaries, and core
  metadata use an organized external library.
- Local content remains under `$EMULATION_ROOT/roms/<system>/` independently of
  the Steam RetroArch installation. Standalone-emulator systems use the same
  hierarchy.
- Core and game input remaps use `$EMULATION_ROOT/configs/remaps`.
- The Xbox Menu button opens RetroArch, RT holds 4x fast-forward, LT rewinds, and
  both the D-pad and left stick control the emulated D-pad.
- Current official Libretro nightlies provide mGBA, SameBoy, Mesen, Snes9x,
  bsnes, Beetle PSX HW, and experimental Panda3DS.

## Fixes required to reach it

1. Run the Steam build once so it creates `retroarch.cfg`.
2. Exit RetroArch and Steam.
3. Create the external library and point RetroArch directories to it.
4. Expose the host paths through Steam Runtime pressure-vessel launch options.
5. Download current cores from the official Libretro x86_64 buildbot and record
   each downloaded archive's SHA-256 hash.

## Quick commands

With Steam fully exited:

```bash
./install-system-packages.sh emulators/frontends/retroarch
./emulators/frontends/retroarch/setup-steam.sh
./emulators/frontends/retroarch/verify-install.sh
```

Refresh only the managed cores later:

```bash
./emulators/frontends/retroarch/update-cores.sh
```

Optional Xbox label-matched mGBA controls (Xbox A becomes GBA A instead of
using Nintendo's positional east button, X/Y become Select/Start, Menu opens
RetroArch, both movement inputs work, and the triggers control rewind/4x speed):

```bash
./emulators/frontends/retroarch/install-mgba-xbox-label-remap.sh
```

Use `EMULATION_ROOT=/another/path` to select a different library before the
first setup. Use `RETROARCH_CONFIG=/path/to/retroarch.cfg` when the Steam
library is outside the automatically searched locations.

## Steam launch options

Complete replacement line for the default library location:

```text
PRESSURE_VESSEL_FILESYSTEMS_RW="/path/to/emulation-data" %command%
```

The read-only mount permits browsing elsewhere under `/data`; the narrower
read/write mount allows RetroArch to update saves, states, playlists, and cores.

## Notes for research

- Initial Steam Runtime testing confirmed `/data` was absent inside the native
  Sniper container. `PRESSURE_VESSEL_FILESYSTEMS_RO` exposed it successfully.
- Controller navigation worked before config changes; no Workshop layout was
  installed.
- RetroArch's default RetroPad layout follows Nintendo/SNES positions: GBA A is
  the east face button, labelled B on an Xbox controller. The optional mGBA
  core remap swaps only emulated GBA A/B, leaving menus and other cores alone.
- The mGBA mapping uses Xbox A/B for GBA A/B and Xbox X/Y for GBA Select/Start.
  View/Back is deliberately unused, avoiding duplicate Select input. Default
  LB/RB remain the only GBA L/R inputs; LT/RT are removed from the core mapping
  so their rewind and fast-forward actions cannot also trigger the shoulders.
  Fast-forward audio remains audible but is not time-stretched, avoiding the
  gradual ramp while switching immediately to the capped 4x rate.
  Keyboard shortcuts remain available: `F1` opens the menu, `L` holds
  fast-forward, `Space` toggles fast-forward, and `R` rewinds.
- Steam DLC cores remain untouched. Managed nightlies are isolated under
  `$EMULATION_ROOT/cores` and can be rolled back from timestamped copies.
- Recommended core mapping: mGBA for GBA, SameBoy for GB/GBC, Mesen for NES,
  bsnes for accurate SNES or Snes9x as fallback, and Beetle PSX HW for PS1.
- Panda3DS is experimental. Standalone [Azahar](https://github.com/azahar-emu/azahar)
  is the recommended 3DS fallback when Panda3DS compatibility is insufficient.
- `emulators/systems.txt` is the shared system-directory catalog. It includes reserved
  standalone or experimental areas such as Switch and PS5. Creating a directory
  does not imply that RetroArch has a core or that games are currently playable.
- BIOS and game files are local material and are never fetched
  by these scripts. PS1 firmware belongs in `$EMULATION_ROOT/bios` with the
  exact filename and hash required by the core documentation.

## TODO (not yet fixed)

- Test one local title per configured system.
- Tune per-core aspect ratio, latency, shader, and controller overrides only
  after baseline compatibility is confirmed.
- Evaluate Panda3DS with local 3DS files and document incompatibilities; add an
  Azahar Steam entry if the Libretro core is not adequate.
