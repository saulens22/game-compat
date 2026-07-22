# Helper app

The Linux Game Compatibility helper is a small native Python/Tk application for
browsing the documented game results and running the repository's scripts. It
does not replace Steam and it does not run silently in the background.

## Launch it

From a cloned repository or an extracted game bundle, open the `game-compat`
directory in a terminal and run:

```bash
./launch-gui.sh
```

If Python Tk is missing, the launch script shows the package command for Arch,
Ubuntu/Debian, or Fedora and asks before running it. No administrator command is
run without that confirmation.

## What updates on launch

Every launch attempts to download the current game catalog and README content
from the repository's `main` branch. This keeps game names, documented results,
TODO items, and links current without requiring a new copy of the app.

If GitHub cannot be reached, the app uses the most recently cached catalog. On a
first offline launch it uses the README files included in the clone or bundle.
The cache is stored under `~/.cache/game-compat/` and contains only public
repository documentation.

Scripts are deliberately not downloaded and executed automatically. Buttons
that change a game use the reviewed scripts in your local clone or bundle; a
newly listed online game therefore remains read-only until its files are
downloaded. Update a clone with `git pull`, or download that game's latest bundle
from its page.

Each game publishes a `versions.json` history. The app compares its current
online version with the locally installed one. **Get script update** appears
only when the online version differs and opens the versioned download section;
it never replaces executable files without the user choosing a download.

## Window behavior

Resize the window freely. The game summary is the scrollable part of the right
panel; action buttons and the status message remain visible at the bottom. The
divider between the game list and details can also be dragged.

The terminal window opened for an action closes after you acknowledge its final
status; the helper does not deliberately leave background terminals running.

To check catalog discovery without opening a graphical window, run:

```bash
./game-compat-launcher.py --self-test
```

## Available actions

- **Read game page** opens the current published instructions.
- **Install requirements** opens the portable package installer in a terminal.
- **Apply setup**, **Verify**, and **Undo fixes** use local per-game scripts and
  are disabled when that script is unavailable.
- **Copy launch options** copies the complete documented replacement line.
- **Open in Steam** opens the edition identified by its Steam App ID.

The app warns before applying or undoing a setup. If Steam is running, applying
a setup is refused so Steam cannot overwrite the configuration change.
