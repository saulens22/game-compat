# Final conclusions

- The canonical win64 Bottles setup with GE-Proton 11-1 is player-confirmed to launch and render at 3840×2160; runner output confirmed `ntsync: up and running`.
- ThirteenAG's current Widescreen Fix is installed and its ASI loader is enabled with `dinput8=n,b`.
- The launcher requests the current display resolution instead of hard-coding a resolution.
- The optional direct Steam shortcut has complete artwork and is player-confirmed with Steam Overlay and the FPS counter. The ordinary Bottles Flatpak wrapper still cannot provide Overlay, matching Valve issue #8952.
- An early research-only direct Steam GE-Proton test failed because its pure win32 prefix was incompatible with current Proton. It is not part of the published installation path.
- The published setup creates `nfsmw-black-edition` as win64 from the start and freshly installs `d3dx9` and `d3dcompiler_47`. No win32 installation or migration is required. Optional Steam Proton sharing of that prefix is confirmed but explicitly documented as brittle.
- Optional HD texture and reflection packs remain research items and are not installed.
