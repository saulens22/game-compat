# Linux gaming basics

This page describes the baseline supported by this repository. Other Linux
configurations may run the games, but the scripts and results are designed for
the setup below.

## Steam edition to use

Use the regular Linux Steam client installed as a native system package for
your distribution. Prefer Steam's stable client channel unless an individual
game page explicitly documents a different tested channel.

Do **not** use Flatpak Steam with these scripts. Flatpak uses sandboxed paths
and permissions that differ from the native client. The scripts currently
discover native Steam libraries, Proton prefixes, controller configuration,
and Steam configuration files. Flatpak was not tested and is unsupported here.

Install Steam through your distribution's normal software manager or its
officially documented Steam package source. Some systems need 32-bit graphics
libraries; the software manager normally installs them as dependencies. Avoid
arbitrary third-party Steam packages.

## Stable, Beta, and Big Picture

- Use the stable Steam client by default.
- Steam Beta is a diagnostic variable, not a general performance fix.
- Big Picture is optional. A game page says when it was actually tested.
- Start with Steam's built-in default controller layout. These scripts never
  install Workshop layouts.

## Proton

When `Proton-GE Latest` is installed, this project treats it as the default
compatibility tool unless a game page names another known-good version.

Use [ProtonPlus](https://protonplus.vysp3r.com/) as the recommended graphical
manager for installing and updating GE-Proton and other compatibility tools.
Choose the native Steam installation as the target, install the version named
by the game page, then fully restart Steam so it appears in Steam's
compatibility-tool list. GE-Proton's own installation documentation also lists
ProtonPlus as an installation method.

ProtonPlus itself may be installed from your distribution or from
[Flathub](https://flathub.org/apps/com.vysp3r.ProtonPlus). Using the ProtonPlus
Flatpak does **not** mean Steam must be Flatpak: this repository still requires
the native Steam client. Confirm that ProtonPlus is targeting native Steam
before installing a tool.

Do not delete a Proton prefix unless saves are backed up and the game page
specifically calls for recreation. A prefix can contain saves, settings, and
installed fixes.

## Graphics drivers

Install the graphics driver and Vulkan packages recommended by your Linux
distribution for your GPU. Both 64-bit and 32-bit Vulkan support can be needed
by older Windows games. Reboot after kernel or proprietary driver updates when
your distribution requires it.

The exact test hardware, driver, Vulkan, desktop, and Proton versions are on
the [Tested environment](TESTED_ENVIRONMENT.md) page. They describe the test
machine rather than universal minimum requirements.

## Wayland, X11, and Gamescope

The research machine uses KDE Plasma on Wayland. Do not switch to X11 merely
because a game is old unless its page identifies a confirmed Wayland problem.

Gamescope is not a default. It adds another display and input layer that can
hide the original problem. Use it only when a case records a known-good reason
and complete launch command.

## Controllers and Steam Input

Connect and test the controller in Steam before installing fixes. Start with
Steam's default layout. If input behaves like a mouse, inspect the active Steam
Input layout before changing Wine or game files.

Fully restart Steam after controller or launch-setting changes. Closing its
window is not the same as choosing **Steam → Exit**.

## Filesystem and game locations

Run the unmodified game once before applying fixes. This creates its Proton
prefix and proves the stock launch path works.

Scripts support common native Steam-library locations and a `STEAM_ROOT`
override. Keep an extracted setup bundle in a stable location because launch
options may contain its absolute path. Linux paths are case-sensitive.

## System requirements

Use the repository installer instead of guessing package names:

```bash
./install-system-packages.sh
```

It reads shared and per-game requirements, detects supported Arch,
Ubuntu/Debian, or Fedora families, and passes the mapped packages to the native
package manager.

## Before applying a setup

1. Confirm the exact Steam edition by App ID.
2. Install and run the stock game once.
3. Read **Default behavior**, **Final behavior**, and **TODO**.
4. Back up important saves.
5. Choose **Steam → Exit** and wait for Steam to stop.
6. Run the complete setup and verifier.
7. Restart Steam and use the launch path documented by the case.

See [Using the game setups](USAGE.md) for bundles, rollback, launch options,
and troubleshooting.
