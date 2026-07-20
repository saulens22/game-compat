# GTA III final results

- Recommended route: original Steam executable through Proton-GE Latest.
- Installed fix stack: SilentPatch III 9.2, Widescreen Fix, and GInput III 1.11.
- Resolution and aspect ratio are automatically derived from the active display.
- Controller preset uses modernized controls with reduced stick sensitivity.
- Keep the in-game frame limiter enabled because gameplay logic remains frame-rate sensitive.
- Wine's built-in Quartz presenter produced intro audio without visible video in testing.
- Native Quartz caused startup failure and is intentionally not enabled.
- The intro wrapper plays the included MPEG files with native `mpv`, then launches the normal Proton command.
- Keyboard, mouse, and controller input skip the complete native intro playlist. The confirmed controller route sends an explicit mpv IPC `quit` command before Proton starts GTA III.
- Steam launch options must reference the current case directory; the obsolete pre-reorganization path prevented the maintained wrapper from running.
- Native `re3` is retained as an optional build experiment, not the default Steam/controller route.
