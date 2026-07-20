---
name: wayland-window-capture
description: Discover and capture a specific KDE Wayland, XWayland, game, Proton, or Wine dialog window together with identifying metadata. Use when the visible window, focus target, dimensions, class, title, or unexpected helper window must be proven.
---

# Wayland window capture

1. Identify the target by exact window ID when possible; otherwise use a narrow title or class regex.
2. Invoke `scripts/capture-window.sh` relative to this skill directory, not from an assumed working directory.
3. Save output under the relevant game's ignored `evidence/` directory.
4. Inspect both the PNG and its adjacent `.window.txt` metadata before drawing conclusions.
5. On KDE Wayland, prefer `kdotool`. Allow the helper's XWayland fallback for Wine surfaces.
6. Capture all candidate Wine windows and properties before blaming ASI loaders, codecs, Proton, or background launch behavior.
7. Keep raw captures out of Git. Put only the final sanitized conclusion in `RESULTS.md`.

Examples:

```bash
/path/to/game-compat/skills/wayland-window-capture/scripts/capture-window.sh --name '^Unhandled Exception$' /path/to/case/evidence/exception.png
/path/to/game-compat/skills/wayland-window-capture/scripts/capture-window.sh --class 'steam_app_12100' /path/to/case/evidence/game.png
```
