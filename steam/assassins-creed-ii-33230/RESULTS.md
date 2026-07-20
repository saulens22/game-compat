# Final conclusions

- Steam build `1843459` launches `AssassinsCreedIIGame.exe` through Ubisoft
  Connect and GE-Proton11-1 using DXVK.
- EaglePatchAC2 v1.1 and Ultimate ASI Loader v4.68 load from the game directory
  with the native `dinput8` override.
- The tested 4K maximum-quality profile holds 60 FPS at startup with 8x MSAA.
- Keep EaglePatch's improved 4096 shadow maps, XInput support, hotplugging, and
  UPlay item restoration enabled.
- Keep `ImproveDrawDistance=0`; upstream reports tie the enabled override to a
  crash when first returning to Florence.
- Xbox letter glyphs require the separate optional Nexus prompt pack and were
  not installed because its authenticated download cannot be redistributed.
