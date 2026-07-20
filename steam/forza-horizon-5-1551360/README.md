# Forza Horizon 5

Steam App ID `1551360`. The stock Steam/Proton path works without a game-specific
fix on the tested system.

## Tested with

- Environment: see the shared [tested environment](../../TESTED_ENVIRONMENT.md).
- Steam edition, build ID `21856128`, `ForzaHorizon5.exe`.
- Initial compatibility tool: inherited `Proton-GE Latest`, resolving to
  `GE-Proton11-1`.
- Normal Steam client on KDE Wayland; Big Picture Mode was not used.
- Xbox Wireless Controller through the unchanged default Steam Input layout.
- Steam Overlay and controller navigation were confirmed by the player.

## Default behavior

- The first launch creates its local WebView and graphics configuration, spends
  roughly 85 seconds in splash/intro startup, and then reaches the title screen.
- The generated graphics configuration selected 3840x2160, VSync, and a 60 Hz
  monitor period. The Turn 10 intro itself displayed at 30 FPS.

## Final behavior

- `ForzaHorizon5.exe` launches directly from the normal Steam client through
  `Proton-GE Latest` with no custom environment variables or wrappers.
- The animated 3840x2160 title screen renders at approximately 60 FPS after the
  30 FPS intro; the player confirmed gameplay, Xbox controller input, correct
  prompts, and Steam Overlay behavior.

## Fixes required to reach it

No game-specific fix is required on the tested setup. Keep the stock launch line
and allow the first startup to finish instead of treating the long intro as a hang.

## Quick commands

No installer is needed. Select `Proton-GE Latest` in Steam if it is not already
the default, then launch normally.

## Steam launch options

The stock baseline uses this complete replacement line:

```text
%command%
```

## Notes for research

- The game is installed as Steam build `21856128` and occupies approximately
  189.7 GB including installed depots.
- The confirmed prefix identifies itself as `GE-Proton11-1`.
- Big Picture Mode is not part of this case.
- Steam attached `gameoverlayui` to the verified live `ForzaHorizon5.exe` PID.
- MangoHud was visible through the machine's existing global setup; it is not a
  required launch option or part of this game's fix.

## TODO (not yet fixed)

- Verify a representative driving scene with a repeatable benchmark before
  publishing performance expectations beyond the confirmed title/game path.
