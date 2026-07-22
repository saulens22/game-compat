# Grand Theft Auto III (classic Steam release)

Steam App ID `12100` on Linux through Proton.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md).
- Compatibility tool: Proton-GE Latest, reported build `GE-Proton11-1`.
- Game edition: classic Steam release, App ID `12100`.
- Input acceptance: Xbox Wireless Controller plus keyboard and mouse.
- Launch acceptance: Steam Big Picture Mode; this result is specific to GTA III.

## Default behavior

- The unmodified classic release uses the original low-resolution presentation and old controller scheme.
- Gameplay is frame-limited, and increasing the rate without appropriate fixes can affect game logic.
- In the tested Proton path, intro audio played while the video surface was transparent.
- Steam input works, but the stock in-game bindings do not feel like a modern GTA controller layout.

## Final behavior

- The original Steam executable launches directly from Steam Big Picture through Proton-GE Latest.
- Resolution and aspect ratio follow the currently active display instead of assuming one fixed monitor.
- Controller input uses a modernized layout with lower stick sensitivity.
- The game keeps its safe in-game frame limiter.
- The included intro videos are visible through a native `mpv` wrapper before the normal Proton launch.
- Keyboard, mouse, and controller buttons skip the complete intro playlist and continue directly to GTA III.

## Fixes required to reach it

The complete setup installs SilentPatch III 9.2, Widescreen Fix, GInput III
1.11, and the intro wrapper. `mpv` is used only for the two included startup MPEG
files because Proton/Wine decoded their audio but did not produce a visible
video surface on the tested setup. After the playlist ends or is skipped, the
wrapper starts the ordinary Steam/Proton command; gameplay does not run through
mpv.

## Quick commands

Install everything:

```bash
cd /path/to/game-compat
./install-system-packages.sh gta3
./steam/grand-theft-auto-iii-12100/setup-steam.sh
```

Use `GTA3_DIR` to override the discovered game directory. Shared setup behavior
is documented in [Using the game setups](../../USAGE.md).

Verify without changing the installation:

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-iii-12100/verify-install.sh
```

Restore the pre-fix files:

```bash
cd /path/to/game-compat
./steam/grand-theft-auto-iii-12100/rollback-fixes.sh
```

## Steam launch options

The setup script writes this complete line, substituting the clone path:

```text
WINEDLLOVERRIDES="d3d8=n,b" /path/to/game-compat/steam/grand-theft-auto-iii-12100/launch-with-intros.sh %command%
```

## Notes for research

### Why the intro wrapper exists

The original game asks DirectShow/Quartz to play `Logo.mpg` and
`GTAtitles.mpg`. Wine's built-in Quartz graph advanced and played sound, but its
video presenter produced a transparent window. Replacing Quartz with a native
Windows component was also tested; GTA III then exited with an access violation.
That path is deliberately not installed.

Native Linux `mpv` displayed the same included MPEG files correctly, so the final
wrapper plays them before starting Proton. During GTA's own DirectShow calls,
the wrapper temporarily substitutes a tiny silent completion clip. This lets
the game advance without replaying audio or opening the broken transparent
presenter. The original files are restored automatically, including on an
interrupted launch.

### How controller skipping evolved

The first native-player attempt exposed mpv controls and accepted only obvious
mouse/keyboard input. The on-screen controls were disabled and a small local
bridge was added to observe Linux joystick/evdev buttons without changing the
Steam controller layout. Sending a Unix process signal was difficult to verify
and did not produce a reliable visible result. The confirmed implementation
sends mpv's documented IPC `quit` command instead: an Xbox `A` press was traced
from `/dev/input/js0` to mpv, which exited immediately before Proton launched
`gta3.exe`.

### Other findings

- After moving this case into the Steam/App-ID directory layout, Steam's stored launch option had to be regenerated to remove the obsolete path.
- Native `re3` was built and tested, but lacked the normal Steam Overlay/controller route; it remains an optional research experiment.

## TODO (not yet fixed)

- Re-test native intro presentation only after a relevant Proton/Wine media change.
