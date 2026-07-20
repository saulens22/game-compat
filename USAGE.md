# Using the game setups

You do not need to know Wine or Proton internals to use a completed setup.
Start with the game page, compare its **Default behavior** and **Final
behavior**, and read **TODO** so you know what remains unfixed.

If Steam, Proton, prefixes, or Linux graphics packages are unfamiliar, read
[Linux gaming basics](LINUX_SETUP.md) first.

## What you need

- A supported Linux distribution: Arch-based, Ubuntu/Debian, or Fedora.
- The Linux Steam client.
- The exact Steam edition shown on the game page, already installed. Steam App
  IDs distinguish releases that may need different fixes.
- An internet connection while the installer downloads system packages and
  checksum-pinned fixes.
- Your normal Linux account. The system-package step may ask for your password
  through `sudo`; typed passwords are normally invisible in a terminal.

Run the unmodified game once before installing fixes. This confirms Steam can
launch it and lets the game create its initial settings.

## Graphical launcher

[Read the complete helper app guide](HELPER_APP.md).

After extracting a game bundle or cloning the repository, open its
`game-compat` directory in a terminal and run:

```bash
./launch-gui.sh
```

The launcher lists available games and provides buttons to read the case,
install requirements, apply a completed setup, verify it, undo it, copy the full
Steam launch-options line, or open the Steam store page. Buttons are disabled
when a game does not provide that action; for example, MK11 has no **Apply
setup** button because no performance fix was found.

The launcher uses the native Python Tk toolkit. If Tk is missing,
`launch-gui.sh` shows the exact distribution package command and asks before
installing it. Actions that need a terminal open one and keep it visible so you
can read the complete output and respond to `sudo` normally.

## Easiest method: download one game bundle

1. Open the page for your game.
2. Read **Tested with**, **Default behavior**, **Final behavior**, and **TODO**.
3. Under **Scripts and downloads**, download the **complete script bundle**.
4. Extract the ZIP. It creates a `game-compat` directory.
5. Open that directory in your file manager, right-click empty space, and choose
   **Open in Terminal**. Desktop wording varies slightly.
6. Run `./launch-gui.sh` for the graphical launcher, or copy the two terminal
   commands displayed below the bundle one line at a time.
7. Fully exit Steam before applying a setup. Closing only the Steam window may
   leave Steam running; use **Steam → Exit** and wait for it to close.
8. Restart Steam after setup and launch the game normally unless its page says a
   different launch path was tested.

Do not move the extracted directory after setup when a game's launch options
contain its path. If you move it, exit Steam and run the setup again.

## Alternative: clone the complete repository

Install Git with your distribution's software manager, then run:

```bash
git clone https://github.com/saulens22/game-compat.git
cd game-compat
```

Now use the **Quick commands** from the selected game page. Cloning is useful
when you want several games or plan to update the scripts later with
`git pull`.

## What the setup changes

A completed Steam setup can perform four kinds of change, all documented on the
game page:

1. Install required Linux packages through the distribution package manager.
2. Download and checksum-verify the listed game fixes.
3. Back up files before replacing them inside the game directory.
4. Select the documented Proton build and write the complete Steam launch-option
   line for that App ID.

The scripts do not install Workshop/community controller layouts. Cases that
protect controller configuration fingerprint it before and after setup and stop
if it changed.

## Check that installation succeeded

Run the game's `verify-install.sh` command from **Quick commands**. Verification
is read-only: it checks expected files and settings without reinstalling them.

If verification fails, copy the complete terminal output when reporting the
problem. The first `Missing:` or `Expected:` line is usually the useful part.

## Undo the fixes

Use the game's rollback command from **Quick commands**. Rollback restores the
local snapshot created before installation. It cannot restore a snapshot that
was never created, so do not delete the extracted case directory while you may
still want to undo the setup.

## Understanding Steam launch options

The game page shows the full replacement line. Copy the complete line into:

**Steam Library → game → Properties → General → Launch Options**

Environment variables appear before `%command%`; game arguments appear after
it. An empty field is Steam's normal default. `%command%` by itself is the
equivalent explicit line.

Usually `setup-steam.sh` writes this setting automatically while Steam is
closed, so manual copying is primarily useful for review or recovery.

## Non-default Steam locations

Scripts discover the common Steam library under your home directory. If Steam
or the game is installed elsewhere, set the override shown on the game page.
For example:

```bash
STEAM_ROOT="/path/to/Steam" ./steam/example-game-123/setup-steam.sh
```

Paths containing spaces must remain inside quotes.

## Safety and privacy

- Fix downloads are version-pinned and checksum-verified.
- Replaced game files receive local rollback copies.
- Logs, configuration snapshots, downloaded archives, and captured evidence are
  excluded from the public repository.
- The repository is primarily AI-created under human direction. Review scripts
  before running them, especially package-install and Steam-configuration tools.
