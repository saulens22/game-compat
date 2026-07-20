# Assassin's Creed Freedom Cry App ID 277590 research notes

- Verify live `ACFC.exe`; do not treat Ubisoft Connect or Steam’s play state as proof.
- Preserve the default Steam controller layout and fingerprint it around setup.
- Do not add an FPS cap: the verified max-quality 4K path was GPU-bound below 60 FPS.
- Preserve resolution and refresh-rate keys. The published script changes quality only.
- `MotionBlur=0` and SMAA are deliberate image choices, not performance concessions.
- Never automate, inspect, store, or publish Ubisoft credentials or product keys.
- Prefer Ubisoft Connect’s tray **Quit** action after a clean game exit; do not
  kill it unless a bounded diagnostic explicitly warns and requires that fallback.
