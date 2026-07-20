# Grand Theft Auto: San Andreas (NewSteam executable)

Steam App ID `12120`, specifically the NewSteam executable, on Linux through
Proton.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md), captured 2026-07-20.
- Compatibility tool: Proton-GE Latest, reported build `GE-Proton11-1`.
- Game edition: NewSteam executable, App ID `12120`.
- Controller mapping: Steam's built-in default gamepad layout.
- Big Picture Mode was not included in this case's acceptance test.

## Default behavior

- The unmodified NewSteam release has none of the compatible SilentPatch corrections installed.
- Steam can select community controller layouts, but those mappings caused incorrect mouse-style input during testing.
- The correct baseline is Steam's built-in default gamepad layout.

## Final behavior

- The original NewSteam executable launches through the normal Steam Play path with Proton-GE Latest.
- SilentPatch SA corrections compatible with this executable are active.
- Full startup splashes remain enabled.
- Steam's built-in controller layout works and no Workshop layout ID is installed by these scripts.

## Fixes required to reach it

The setup installs SilentPatch SA 33.1 through its packaged ASI loader while
deliberately omitting the incompatible Widescreen Fix ASI. SilentPatch is kept
because this version's compatible corrections loaded successfully; adding more
ASIs was not treated as automatically better after the unsupported widescreen
module produced an empty loader-window failure.

## Quick commands

Install everything:

```bash
cd /path/to/game-compat
./install-system-packages.sh sa
./steam/grand-theft-auto-san-andreas-12120/setup-steam.sh
```

Use `GTASA_DIR` to override the discovered game directory. Shared setup behavior
is documented in [Using the game setups](../../USAGE.md).

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-san-andreas-12120/verify-install.sh
```

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-san-andreas-12120/rollback-fixes.sh
```

## Steam launch options

Use this complete replacement line:

```text
WINEDLLOVERRIDES="vorbisFile=n,b" %command%
```

## Notes for research

- The Widescreen Fix ASI is unsupported by this executable revision and caused the empty ASI-loader-window failure path.
- Steam may need to restart before controller-layout changes are reflected.
- `gta-reversed` is a development/research project, not the recommended play route.
- The default Steam controller layout was restored after a Workshop mapping turned the controller into mouse-style input; the setup now fingerprints controller configuration to prevent that regression.
- Big Picture Mode was not part of this case's acceptance test and is not claimed as verified here.

## TODO (not yet fixed)

- Find a maintained widescreen solution that explicitly supports the NewSteam executable before adding one.
- Keep monitoring decompilation/reimplementation projects, but do not substitute them for the installed Steam launch without a tested migration path.
