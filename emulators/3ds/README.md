# Nintendo 3DS emulation

## Tested with

- RetroArch 1.22.2 from Steam App ID 1118310 on KDE Wayland.
- Managed Panda3DS Libretro core `0.9.3a9f08a`.
- Steam Linux Runtime with the configured external emulation directory exposed
  by the documented launch options.
- No 3DS game was available during testing.

## Default behavior

The repository installs Panda3DS as an experimental RetroArch core. The Steam
RetroArch executable depends on its Steam Runtime and fails when invoked
directly outside Steam because `libCg.so` is not present in the host library
path.

## Final behavior

RetroArch starts correctly through Steam and loads the Panda3DS core without a
dependency or initialization error. Game compatibility is not yet established.

## Fixes required to reach it

Run RetroArch through Steam with the configured external-library launch options.
Keep 3DS game files under `$EMULATION_ROOT/roms/3ds/`. Do not install a
standalone emulator until a real title demonstrates that Panda3DS is inadequate.

## Quick commands

Verify the shared RetroArch installation and managed cores:

```bash
./emulators/frontends/retroarch/verify-install.sh
```

Refresh managed cores from the official Libretro build service:

```bash
./emulators/frontends/retroarch/update-cores.sh
```

## Steam launch options

Use the complete RetroArch launch-options line, replacing the placeholder with
the external library location:

```text
PRESSURE_VESSEL_FILESYSTEMS_RO="/path/to/emulation-data" PRESSURE_VESSEL_FILESYSTEMS_RW="/path/to/emulation-data" %command%
```

## Notes for research

Loading a core proves only that its shared library and dependencies initialize.
A 3DS game must still be tested for boot, graphics, audio, saves, performance,
input, and dual-screen presentation. Standalone
[Azahar](https://github.com/azahar-emu/azahar) remains the preferred fallback if
Panda3DS compatibility is insufficient.

## TODO (not yet fixed)

- Place a legally dumped 3DS title in `$EMULATION_ROOT/roms/3ds/` and test it.
- Compare the same title with current standalone Azahar only if Panda3DS fails.
- Verify Xbox controller mapping and an appropriate dual-screen layout.
