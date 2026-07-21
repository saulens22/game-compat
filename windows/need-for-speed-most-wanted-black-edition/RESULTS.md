# Final conclusions

- The canonical win64 Bottles setup with GE-Proton 11-1 is player-confirmed to launch and render at 3840×2160; runner output confirmed `ntsync: up and running`.
- ThirteenAG's current Widescreen Fix is installed and its ASI loader is enabled with `dinput8=n,b`.
- The launcher requests the current display resolution instead of hard-coding a resolution.
- The optional direct Steam shortcut has complete artwork and is player-confirmed with Steam Overlay and the FPS counter. The ordinary Bottles Flatpak wrapper still cannot provide Overlay, matching Valve issue #8952.
- An early research-only direct Steam GE-Proton test failed because its pure win32 prefix was incompatible with current Proton. It is not part of the published installation path.
- The published setup creates `nfsmw-black-edition` as win64 from the start and freshly installs `d3dx9` and `d3dcompiler_47`. No win32 installation or migration is required. Optional Steam Proton sharing of that prefix is confirmed but explicitly documented as brittle.
- Xbox 360 Stuff Pack 4.1 Easy Installation and NFS HD Reflections are installed
  and player-confirmed. The live process loaded Stuff, Xenon Effects, TexWizard,
  Widescreen Fix, HD Reflections and Steam Overlay together.
- The working widescreen combination disables `FixHUD`, `Scaling` and
  `FMVWidescreenMode` for Xbox 360 Stuff but keeps registry-backed automatic
  resolution. `WriteSettingsToFile=1` was rejected because it generated
  `g_RacingResolution=1` and caused corner-sized, glitched presentation.
- Xbox controller support works through Steam and the Widescreen Fix. The player
  manually selected a preferred modern mapping; XtendedInput was not installed.
