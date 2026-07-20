# Assassin's Creed Brotherhood App ID 48190 research notes

- Verify live `ACBSP.exe`; a lingering Ubisoft `upc.exe` is not proof of launch.
- Keep `PROTON_PREFER_SDL=1`: the tested path otherwise selected keyboard/mouse
  input and lost native controller operation.
- Preserve the default Steam Input layout and fingerprint it around setup.
- Keep the 60 FPS cap. Do not remove it based only on menu performance; several
  missions and controls are known to malfunction at higher frame rates.
- `PostFX=0` is a deliberate motion-blur/bloom removal, not a performance preset.
- Never automate, inspect, save, or publish Ubisoft credentials.
- The launcher can remain headless after a normal in-game exit and hold Steam's
  App 48190 session open. Distinguish that from a game crash.
