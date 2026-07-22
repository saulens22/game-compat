# Xidi

[Xidi](https://github.com/samuelgr/Xidi) lets an older Windows game see a modern
XInput controller as a legacy DirectInput or WinMM controller. It can be useful
when an Xbox controller works in modern games but an older game cannot detect
it through the controller API that game expects.

This repository does not redistribute Xidi. Download the current release from
the [official Xidi releases page](https://github.com/samuelgr/Xidi/releases)
and use the [upstream documentation](https://github.com/samuelgr/Xidi/wiki) as
the authority for supported files and configuration.

## When Xidi is appropriate

Consider Xidi only after confirming all of the following:

- The game expects DirectInput or the older WinMM joystick API.
- The physical controller works on Linux and is visible inside the game's Wine
  or Proton environment.
- The game does not already receive a suitable controller from Steam Input,
  SDL, Wine, Proton or another wrapper.
- Logs or loaded-module inspection can confirm which controller API the game
  actually opens.

Xidi is not a general controller remapper. A game's own controller-profile file
usually describes button actions; it does not make an unsupported device API
start working.

## Choose the correct files

First determine whether the game executable is 32-bit or 64-bit:

```bash
file /path/to/Game.exe
```

Use Xidi's `Win32` files for a `PE32` executable and its `x64` files for a
`PE32+` executable. The bottle or operating system being 64-bit does not make a
32-bit game executable 64-bit.

For the classic proxy-loading method, choose only the API the executable
imports:

| Game import | Xidi proxy | Typical Wine override |
| --- | --- | --- |
| `DirectInputCreateA` from `dinput.dll` | `dinput.dll` | `dinput=n,b` |
| `DirectInput8Create` from `dinput8.dll` | `dinput8.dll` | `dinput8=n,b` |
| WinMM joystick functions | `winmm.dll` | `winmm=n,b` |

Inspect imports without launching the game:

```bash
objdump -p /path/to/Game.exe | rg -i 'dinput8?|winmm'
```

Copy the matching proxy and Xidi main DLL from the same architecture directory
in the official archive to the directory containing the game executable. Do
not install all three proxies merely to see whether one works; duplicate input
paths make diagnosis harder.

Xidi v5 also offers its upstream-recommended HookModule method. Follow the
[official getting-started guide](https://github.com/samuelgr/Xidi/wiki/Getting-Started)
for that method because it additionally uses Hookshot and changes how the game
is started.

## Wine, Proton and Bottles

The proxy must load as native before Wine falls back to its built-in DLL. For
example, a game using legacy DirectInput normally needs:

```text
WINEDLLOVERRIDES="dinput=n,b" %command%
```

For a Bottles program, add the equivalent environment variable to that game's
bottle. For a Steam shortcut, place environment variables before `%command%`.
Preserve overrides already required by graphics or ASI-loader fixes by joining
entries with semicolons, for example:

```text
WINEDLLOVERRIDES="d3d9=n,b;dinput=n,b" %command%
```

Xidi requires the Microsoft Visual C++ 2022 runtime. In Bottles, install it
freshly in the affected game's bottle with Winetricks instead of copying DLLs
from another prefix:

```bash
flatpak run --command=bottles-cli com.usebottles.bottles winetricks \
  -b GAME_BOTTLE vcrun2022
```

Replace `GAME_BOTTLE` with the bottle's name. A 32-bit game inside a 64-bit
bottle still needs the 32-bit runtime components installed by Winetricks.

## Verify before accepting the result

Confirm more than menu navigation:

1. Verify the intended proxy and Xidi main DLL are loaded in the live game.
2. Check how many controllers the game exposes. Unexpected duplicates are a
   reason to stop and inspect the input stack.
3. Test controller selection, gameplay, pause menus, both sticks, D-pad,
   triggers, shoulder buttons and vibration where applicable.
4. Confirm Steam Overlay and existing graphics fixes still work through the
   player's normal launch path.

Xidi logging can be enabled through `Xidi.ini`; see the
[official configuration guide](https://github.com/samuelgr/Xidi/wiki/Configuration).
Logs showing that Xidi created virtual devices are not sufficient by themselves:
the game must also acquire and poll one of those devices during gameplay.

## Rollback

Before installation, back up any same-named DLL and configuration file from the
game directory. To remove Xidi, restore those exact originals and remove only
the Xidi files that were added. Also remove the corresponding DLL override from
the bottle or Steam launch options.

Never delete a pre-existing `dinput.dll`, `dinput8.dll` or `winmm.dll` without a
verified backup. Another mod may already depend on it.

## Known limitation from NBA Live 07 research

Xidi was fully loaded and produced four working virtual controllers during the
NBA Live 07 investigation. The game displayed them in controller setup, but it
never acquired or polled any of those Xidi devices during gameplay. Installing
different `dinput`, `dinput8` and `winmm` proxies did not change that result.

That failure is an important diagnostic boundary: if a game can list an Xidi
device but never reads it in the affected gameplay path, more Xidi mappings or
additional proxy DLLs are unlikely to solve the problem. Remove Xidi and test a
different input path instead.
