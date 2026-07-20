# GTA classic trilogy: fixes, reverse-engineering projects, and 4K options

Research snapshot: 2026-07-20. Verify upstream versions before relying on this
document for a new installation.

## Executive conclusion

The similarly named projects are not one uniform trilogy package:

| Game | Reverse-engineering project | State | Practical player option now |
| --- | --- | --- | --- |
| GTA III | `re3`, `master` branch | Complete standalone source port; last mirrored source commit `310dd8637147c4db643107b69d603902abc78141` (2022-01-14) | Credible native-Linux alternative to the original executable |
| Vice City | `reVC`, `miami` branch in the same tree | Complete standalone source port; branch head `37e9ec0d19cbd3cd25823089380fcdae558bee0b` | Credible native-Linux alternative to the original executable |
| San Andreas | `gta-reversed/gta-reversed` | Active but only about 50–60% reversed; produces a Windows DLL that replaces functions in a specific original executable | Research/development experiment, not the recommended way to play the story |

For a stable and faithful high-resolution play-through, use the original PC
games with SilentPatch and Widescreen Fix where the executable is supported.
For III and Vice City, evaluate the native `re3`/`reVC` ports as isolated
alternatives rather than mixing them with ASI plugins. For San Andreas, retain
the patched original game; do not deploy `gta-reversed` as the main play copy.

## What `re3` and `reVC` provide

The source tree describes GTA III (`master`) and Vice City (`miami`) as fully
reversed. It supports Linux, Windows, macOS, and FreeBSD across several CPU
architectures. Native rendering uses the homebrew `librw` RenderWare
replacement with OpenGL, and native audio can use OpenAL. Original game assets
are still required.

Relevant built-in improvements include:

- Correct widescreen FOV, HUD, and menu scaling.
- Numerous bug fixes, configurable through compile-time options.
- PS2/Xbox rendering features, XInput support on Windows, map and debug tools.
- Settings in `re3.ini` and user files in the game root.

The source-port route is not the same as installing fixes into the original
game. Code-changing DLL/ASI mods, including conventional limit adjusters, do
not work. The project says equivalents of much of SilentPatch, Widescreen Fix,
SkyGFX, and GInput are already integrated. Asset replacements mostly remain
compatible.

Known tradeoffs:

- The maintained upstream was removed after legal action; the available tree
  is an archival mirror of `halpz/re3`, not a normally maintained official
  release channel.
- Its own to-do list still calls out high-FPS physics. Native 4K does not imply
  that uncapped or 60 FPS gameplay is safe.
- Saves/settings live differently, and binary ASI mods for the original engine
  cannot simply be carried across.
- It has no conventional software license; the README limits the intended use
  to education, documentation, and modding.

Source: [archival re3/reVC mirror](https://git.shihaam.dev/archivemirrors/re3)
and its [README](https://git.shihaam.dev/archivemirrors/re3/src/branch/master/README.md).

## What `gta-reversed` for San Andreas is

`gta-reversed` is active: GitHub reported a latest source commit of
`155c20f8cbe1cc30382f8f16c51e8fe25988ee36` dated 2026-07-13. However, it is
not a San Andreas equivalent of the finished `re3` executable.

The project currently builds a Windows DLL. Loaded into the original game, it
replaces reversed functions while the remaining game continues to run from the
original executable. The project estimates 50–60% completion and gives no
completion date. Its goal is eventually to produce a standalone executable.

It specifically requires the 5,189,632-byte "Compact" executable, which is not
the ordinary 1.0 US executable and is not the installed 5,971,456-byte Steam
`gta-sa.exe`. It also discourages unrelated plugins. Although the repository
contains a Linux-hosted MSVC/Wine build procedure, that procedure builds the
Windows plugin; it does not create a native Linux San Andreas port.

Current GitHub Actions publish build artifacts, which is useful for developers
but does not change those runtime requirements.

Source: [`gta-reversed/gta-reversed`](https://github.com/gta-reversed/gta-reversed)
and its [Linux-hosted Windows build notes](https://github.com/gta-reversed/gta-reversed/blob/master/contrib/msvc-wine/README.md).

## Patch-based original games

SilentPatch and Widescreen Fix are complementary:

- SilentPatch fixes crashes, blockers, gameplay bugs, and many smaller visual
  issues while aiming to preserve the original experience. The latest release
  observed was "2024 Update Hotfix #2" (III 9.2, VC 11.1, SA 33.1), published
  2026-04-22.
- Widescreen Fix supplies the more complete resolution-independent presentation:
  correct FOV, HUD/menu/subtitle/radar scaling, and related display fixes.

Widescreen Fix officially supports any executable for GTA III and Vice City
(1.0 recommended), but its San Andreas entry specifies 1.0 US. The installed
San Andreas copy is the later Steam build, so a full SA widescreen setup needs
a separately planned downgrade with save and game-file backups. SilentPatch
itself supports selected fixes on newer Steam/Rockstar executables.

Sources: [SilentPatch](https://github.com/CookiePLMonster/SilentPatch),
[SilentPatch releases](https://github.com/CookiePLMonster/SilentPatch/releases),
and the [Widescreen Fixes Pack](https://fusionfix.io/wfp).

## Recommended evaluation order

1. Preserve current saves and settings for each game.
2. Establish an original-executable baseline at the display's native resolution and 30 FPS.
3. Install only current SilentPatch plus Widescreen Fix for III and VC, then
   verify each separately under Proton.
4. Build pinned native `re3` and `reVC` copies outside the Steam install and
   compare them without altering the patched baseline.
5. For SA, decide separately whether the benefits of a 1.0 downgrade justify
   save conversion and Steam-update protection. Do not use `gta-reversed` as a
   general fixes pack.
6. Add visual restorations (for example SkyGFX) only after the stable 4K base is
   verified. Avoid giant mixed modpacks until individual components are known-good.
