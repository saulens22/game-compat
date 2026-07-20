# Final conclusions

- Steam build `252091` launches the supported `AssassinsCreed_Dx10.exe` through
  GE-Proton11-1 using WineD3D/OpenGL.
- EaglePatchAC1 v1.1 and Ultimate ASI Loader v4.68 load from the game directory
  with the native `dinput8` override.
- The tested 3840x2160 maximum-quality profile uses 4x MSAA and removes motion
  blur by disabling the game's bundled Post FX option.
- A hidden 32-bit MangoHud hook caps the DX10 path at 60 FPS; the simpler
  `DXVK_FRAME_RATE` limiter was ineffective because this path does not use DXVK.
- EaglePatch's XInput path, triggers, hotplugging, and later-game-style control
  layout are active without changing the default Steam Input layout.
- Xbox letter glyphs require the separate optional Nexus prompt pack and were
  not installed because its authenticated download cannot be redistributed.
- Final stick sensitivity and controller feel still need player acceptance.
