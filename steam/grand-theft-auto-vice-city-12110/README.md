# Grand Theft Auto: Vice City (classic Steam release)

Steam App ID `12110` on Linux through Proton.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md), captured 2026-07-20.
- Compatibility tool: Proton-GE Latest, reported build `GE-Proton11-1`.
- Game edition: classic Steam release, App ID `12110`.
- Controller mapping: Steam's built-in layout.
- Big Picture Mode was not included in this case's acceptance test.

## Default behavior

- The unmodified classic release retains its original rendering and widescreen limitations.
- It has no SilentPatch or Widescreen Fix corrections.
- Steam's built-in controller layout is available and should not be replaced by a Workshop mapping.

## Final behavior

- The original Steam executable launches through the normal Steam Play path with Proton-GE Latest.
- Resolution and aspect ratio follow the active display.
- SilentPatch compatibility corrections are active.
- Steam's built-in controller layout remains unchanged.

## Fixes required to reach it

The complete setup installs SilentPatch VC 11.1 for engine compatibility
corrections and Widescreen Fix so resolution/aspect behavior follows the active
display instead of baking in one monitor. These are loaded into the original
Steam executable; the game is not replaced by a reimplementation.

## Quick commands

Install everything:

```bash
cd /path/to/game-compat
./install-system-packages.sh vc
./steam/grand-theft-auto-vice-city-12110/setup-steam.sh
```

Use `GTAVC_DIR` to override the discovered game directory. Shared setup behavior
is documented in [Using the game setups](../../USAGE.md).

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-vice-city-12110/verify-install.sh
```

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-vice-city-12110/rollback-fixes.sh
```

## Steam launch options

Use this complete replacement line:

```text
WINEDLLOVERRIDES="d3d8=n,b" %command%
```

## Notes for research

- Native Quartz and prefix codec overrides regressed startup and are intentionally not part of the final setup.
- `reVC` is retained as upstream research rather than the normal Steam route.
- The final route stayed with the original executable because that preserved normal Steam integration and the working built-in controller layout.
- Big Picture Mode was not part of this case's acceptance test and is not claimed as verified here.

## TODO (not yet fixed)

- Native in-game intro-video compatibility under Proton is not solved by the tested codec overrides.
- Revisit `reVC` only if a maintained, legally usable build path becomes appropriate for the installed assets.
