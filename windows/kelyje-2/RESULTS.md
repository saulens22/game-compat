# Final conclusions

- User-confirmed result: Kelyje II 7.3 reaches and remains at its Lithuanian menu at 4K from the canonical win64 GE-Proton bottle.
- `home=__noinst` and `base=__noinst` caused the immediate exit.
- A complete install with `home=.`, `base=.`, `movie=.`, and `source=.` provides the confirmed no-CD path without a host mount or modified executable.
- D2GI 0.5 loaded successfully, identified version 7.3, and selected 3840x2160 dynamically in the confirmed run.
- Ligos Indeo 5.11 is installed and IV50 is registered, but the introductory video still does not play. The player accepted this limitation.
- Windows XP compatibility is the retained known-good identity; Windows 98 was not required.
- Optional direct Steam integration is confirmed with one shortcut, D2GI widescreen, Steam Overlay and the FPS counter. It requires `ddraw=n,b;ir50_32=n,b`; without that override Steam loads Proton's built-in DirectDraw and loses widescreen support.
- Steam Proton and Bottles share the same prefix for this optional integration. This is explicitly documented as brittle and should be snapshotted before runner changes.
- No controller behavior was investigated.
