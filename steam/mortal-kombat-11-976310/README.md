# Mortal Kombat 11 on Linux

Steam App ID `976310` through Proton.

## Tested with

- Shared hardware and packages: [tested environment](../../TESTED_ENVIRONMENT.md), captured 2026-07-20.
- Compatibility tools compared: GE-Proton 9-11, GE-Proton 10-34, Proton-GE Latest `GE-Proton11-1`, and Proton Experimental.
- Renderers compared: the live `MK11.exe` DX11 path and `MK11_DX12.exe` DX12 path.
- GPU evidence: NVIDIA RTX 4060 Laptop GPU selected, with low utilization during the failure.
- Displays tested as explicit variables: 3840x2160 at 60 Hz over HDMI and 2560x1600 at 60 Hz on the internal panel.

## Default behavior

- The game launches and reaches animated menus and gameplay.
- Performance falls into a repeating 7/14 FPS cadence, normally around 11–14 FPS and never sustaining more than roughly 15 FPS during gameplay.
- GPU utilization remains low rather than showing normal GPU saturation.
- Steam may launch `MK11.exe` even when a test intended to exercise `MK11_DX12.exe`.

## Final behavior

No playable configuration was found. Proton-GE Latest remains the normal
compatibility choice, but it does not fix performance on the affected setup.
`FrameSkip = 1` is preserved so online play remains available.

## Fixes required to reach it

There is currently no known fix to install. The downloadable scripts reproduce
a bounded diagnostic for comparing a genuinely new Proton, driver, kernel,
game, or compositor version; they are not presented as a performance fix.

## Quick commands

Install the diagnostic requirements:

```bash
/path/to/game-compat/install-system-packages.sh mk11
```

Then run a future comparison from the extracted case bundle:

```bash
./run-dx12-diagnostic.sh \
  --proton "$HOME/.local/share/Steam/compatibilitytools.d/Proton-GE Latest" \
  --duration 90 --label update-check
```

Use `./summarize-diagnostic.sh RUN_DIRECTORY` afterward. The runner discovers
the default Steam installation or accepts `STEAM_ROOT`, `MK11_DIR`, and
`MK11_PREFIX` overrides; generated evidence remains local.

## Steam launch options

No custom launch option tested here fixed the low frame rate. For ordinary play,
leave the field empty; `%command%` is the equivalent explicit replacement:

```text
%command%
```

## Notes for research

| Test | Variants checked | Result |
| --- | --- | --- |
| Renderer | DX11 and DX12 | Both remained around 7–14 FPS. |
| Proton | GE-Proton 9-11, GE-Proton 10-34, Proton-GE Latest 11-1, and Proton Experimental in an isolated prefix | No version restored normal performance. |
| Graphics | Existing settings and minimum preset | Minimum settings still produced a benchmark result of 14 FPS. |
| Display | 4K/60 HDMI and 2560x1600/60 internal display | The low-FPS cadence followed the game rather than the display. |
| Window mode | Fullscreen and borderless | No material performance change. |
| Steam | Overlay enabled/disabled and stable/beta client paths | No material performance change. |
| Frame skipping | `FrameSkip = 1` and a temporary diagnostic test with `0` | Performance was unchanged; `0` disables online play, so `1` was restored. |
| Wine synchronization | Default behavior, NT sync disabled, and all fast synchronization paths disabled | No material performance change. |
| VKD3D scheduling | Immediate present-mode override | The override was active, but performance was unchanged. |
| GPU integration | NVAPI disabled while confirming the discrete GPU remained selected | No improvement; GPU utilization remained low. |
| Other toggles | Large-address-aware disabled, write-watch investigation, and `noforcelgadd` | None fixed the low frame rate. |

A static transition briefly reported about 60 FPS, but animated content and
gameplay immediately returned to the low cadence. This was not a successful
result.

## TODO (not yet fixed)

- Identify the source of the low 7/14 FPS scheduling cadence.
- Re-test after a relevant Proton, Wine, VKD3D, driver, kernel, game, or compositor update.
