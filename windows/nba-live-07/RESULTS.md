# NBA Live 07 results

- A dedicated win64 Bottles environment using GE-Proton 11-1, DXVK 3.0.2 and
  NT sync was created successfully.
- The installer DirectX 9.0c error was caused by its obsolete DirectX setup
  engine rejecting a modern 64-bit environment, not by missing registry state.
- Replacing only `DSETUP.dll`, `dsetup32.dll`, and `DXSETUP.exe` with the
  checksum-pinned Microsoft DirectX June 2010 versions allowed setup to finish.
- The original executable reaches its obsolete CD check. A preserved replacement
  executable bypassed that check and opened a full-screen game window.
- The first GE-Proton launch exposed six missing WineD3D support files after
  the runner change. Restoring them from GE-Proton's own default-prefix
  template allowed DirectDraw to initialize; runtime DirectX DLLs remain
  installed through Bottles Winetricks rather than copied from another bottle.
- DXVK 3.0.2 selected the NVIDIA GPU and created the game window successfully.
- The stock controller path received modern Xbox-family DirectInput reports but
  failed NBA's exact device-name profile lookup. The published native-profile
  fallback preserves recognized devices and assigns EA's bundled Xbox profile
  only to otherwise unknown controllers.
- Three connected controllers each received all 18 native gameplay bindings.
  The player confirmed that the dual-stick layout worked and returned to the
  main menu without a crash on the concluding test.
- Steam integration and the Overlay work through the shared Bottles prefix.
- The stock executable's shutdown cleanup deadlocked after its window closed.
  A checksum-guarded, reversible branch patch now selects the game's own
  post-main-loop termination path; the player confirmed menu exit and the game,
  Proton chain, Overlay helper, and Steam Running state all cleared.
- Complete Steam library artwork is generated from checksum-pinned cover and
  logo sources for the single NBA Live 07 shortcut.
- FIFAM ASI Loader and Resolution v1.04 both loaded, but the current replacement
  executable was incompatible: the documented custom slot still created a real
  640x480 swapchain. This is not accepted as a widescreen fix.
