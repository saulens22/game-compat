# NBA Live 07

This guide installs the 2006 PC game in an isolated Bottles environment. The
installer repair, direct Bottles startup, Steam integration, clean shutdown and
modern Xbox-family controller support are confirmed. Widescreen correctness is
still under investigation.

## Tested with

- Shared computer and Linux packages: [tested environment](../../TESTED_ENVIRONMENT.md).
- North American English PC release.
- Bottles Flatpak 64.1 with a dedicated `nba-live-07` win64 Gaming bottle.
- GE-Proton 11-1, DXVK 3.0.2 and NT sync.
- Fixed executable SHA-256:
  `b5a69861faae630a4204ee06e3ade8b70ebea48ff3f7f7629a47b8aa6547b039`.
- Direct Bottles startup with a full-screen game window, DXVK 3.0.2 and the
  NVIDIA GPU.
- Steam shortcut launch with Steam Input's default layout and three connected
  Xbox-family controllers. All three received the complete 18-binding gameplay
  profile. The player confirmed the layout and a safe return to the main menu.

## Default behavior

The game installer reports that DirectX 9.0c is required even when the bottle
already reports DirectX `4.09.00.0904`. Its bundled 2006 DirectX setup engine
recognizes that version, then rejects the modern 64-bit Windows environment as
an unsupported Windows version.

The installed game is designed for 4:3 displays and uses obsolete disc-driver
protection. Native modern widescreen rendering therefore requires separate
community fixes after the official game update.

The confirmed stock runtime window was full-screen, but the rendered resolution
was unacceptably low. The Xbox controller did not operate through the direct
Bottles path during the player's test.

## Final behavior

Setup completes in a dedicated win64 GE-Proton bottle with DXVK and NT sync.
The confirmed repair keeps the installer's DirectX requirement intact and
replaces only the obsolete DirectX setup engine with Microsoft's June 2010
release.

The fixed executable starts directly through Bottles without the CD check.
DXVK 3.0.2 selects the NVIDIA GPU and creates a full-screen game window. No
automated input or gameplay was used to make that claim.

The game now exits cleanly from its own menu and Steam returns from Running to
Play. A checksum-guarded executable patch avoids NBA Live 07's known shutdown
deadlock by selecting the termination path already present in the game after
its main loop returns.

The Steam Overlay works through the direct Proton integration. The native
controller-profile fallback gives modern Xbox-family controllers EA's complete
dual-stick mapping. The player confirmed the controls and subsequently returned
to the main menu without a crash. Steam library artwork can be generated and
installed for the one NBA Live 07 shortcut.

## Fixes required to reach it

### Installer DirectX repair

`fix-installer-directx.sh` downloads Microsoft's DirectX June 2010
redistributable, verifies its SHA-256 checksum, preserves the three original
setup-engine files and installs the newer `DSETUP.dll`, `dsetup32.dll`, and
`DXSETUP.exe`. The player confirmed that the normal installer then completed.

Changing the advertised DirectX requirement or setting an `Installed=1`
registry value did not work: the installer performs its own check and rewrites
that value. Those rejected bypasses are not part of the scripts.

### Official game update and modern executable

The [official update guide](https://www.nba-live.com/nbalivewiki/index.php/Installing_the_official_patch_for_NBA_Live_07)
recommends EA's bug-fix patch and warns that its language and distribution must
match the installed game. It fixes substitution logic, direct-pass text,
jerseys, statistics and several gameplay issues. This case needs the North
American English version; it has not been applied yet.

The [NLSC fixed executable](https://forums.nba-live.com/downloads.php?df_id=13575&view=detail)
replaces the obsolete protection used by the original executable. It expects
the official 1.1 update first and has not yet been installed or tested here.

The currently available replacement executable bypassed the CD check and
reached the game window. Its original counterpart is preserved locally. It is
not yet claimed to be the NLSC 1.1 build because the matching official updater
has not been applied and the NLSC archive has not been checksum-compared.

### GE-Proton runtime repair

Changing an existing bottle from another runner to GE-Proton can leave WineD3D
without `libvkd3d-1.dll`, `libvkd3d-shader-1.dll`, and
`libvkd3d-utils-1.dll` for both architectures. The game then exits before a
window with a `DDRAW.DLL` import failure.

`configure-runtime.sh` installs optional DirectX 9 components freshly through
Bottles Winetricks, then restores those six WineD3D support files from the
selected GE-Proton runner's own default-prefix template. It never copies DLLs
from another game bottle.

### Widescreen

[NBA Live Resolution v1.04](https://github.com/muratcansarkalkan/NBALiveResolution/releases/tag/v1.04)
provides native custom resolutions and corrected widescreen UI for NBA Live
2005–08. Its upstream instructions also require the fixed executable and FIFAM
ASI Loader. Resolution must be chosen for the user's current display; this case
will not hard-code 4K or any other size. Installation remains pending until the
official update and fixed executable are in place.

The exact required [FIFA Manager ASI Loader (DirectX9)](https://forums.nba-live.com/downloads.php?df_id=13583&view=detail)
is hosted by NLSC. Its current archive is
`FIFAM-ASI-LOADER-1_0_5_0-D3D9.zip`, with published MD5
`25bd9be0efd9dddba77655b2568c2d80`. NLSC requires an authorized browser
session for the download, so the setup will verify a player-downloaded archive
rather than silently substituting a different ASI loader.

The loader and `Resolution.asi` were confirmed in the live process, but the
current replacement executable did not match the plugin's expected NBA Live 07
addresses. Selecting its documented `640x480x32` custom slot still produced an
actual 640x480 DXVK swapchain. The widescreen result is therefore rejected
until the matching official 1.1 update and NLSC 1.1 fixed executable are used.

### Xbox controller

NBA Live 07 uses legacy DirectInput. Three Xbox-family controllers were visible
to Linux, Steam and Wine, and all produced changing DirectInput reports. NBA
also enumerated all three, but its exact-name registry returned no controller
profile for `Controller (Xbox One For Windows)` or `Xbox One S Controller`.
Missing host access, Steam controller assignment and missing raw input are
therefore ruled out.

The controller ASI preserves every profile NBA recognizes and supplies the
bundled `XboxWiredGamepad.jfg` only when NBA's native lookup returns no profile
for a controller. NBA's own loader and binder then create all 18 mappings for
each controller. Source, a reproducible build script, the compiled ASI and a
reversible installer are included in `controller-fix/`.

Contemporary players also reported that the PC release did not handle Xbox 360
analog triggers correctly. EA's bundled profile does not use LT or RT; the
confirmed layout uses the bumpers and ten digital buttons instead.

### Controller schema

The recommended layout follows EA's bundled Xbox profile and the original
PC/PS2/Xbox control scheme. NBA's internal action labels are older engine names,
so the table uses the behavior a player sees:

| Xbox control | Gameplay behavior |
| --- | --- |
| Left stick | Move the controlled player |
| Right stick | Total Freestyle Control; advanced moves use directional flicks and half-circles |
| A | Pass on offense; switch player on defense |
| B | Jumpshot on offense; take a charge on defense |
| X | Layup on offense; steal/intercept on defense |
| Y | Dunk on offense; block/rebound on defense |
| LB | Direct-pass or direct-player-selection modifier |
| RB | Turbo |
| Back | Play-call, timeout or intentional-foul context |
| Start | Pause menu |
| Left-stick click | Fake/context action |
| Right-stick click | Direct-shot/Freestyle context action |
| D-pad | Four quick plays |
| LT / RT | Unused by EA's bundled PC profile |

The right stick must remain analog. EA designed it for freestyle moves, special
passes, shots and dunks; it is also used for back-down/pro-hop behavior and the
down/up free-throw motion. Mapping it to four ordinary buttons would remove
advanced motions. Holding the Freestyle Superstar modifier while moving or
clicking the right stick selects or performs higher-tier special moves.

This layout is supported by the [EA producer interview hosted by
NLSC](https://www.nba-live.com/nbalive07/interview-pc/), the [NLSC NBA Live 07
FAQ](https://www.nba-live.com/nbalivewiki/index.php/NBA_Live_07_FAQs), its
[right-analog free-throw explanation](https://www.nba-live.com/nbalivewiki/index.php/Right_Analog_Method),
and a [contemporary transcription of the original control
sheet](https://www.neoseeker.com/forums/33229/t964646-nba-live-07-playstation-2-buttons/).
The unresolved trigger limitation was also [reported by Xbox 360 controller
users when the PC game was current](https://forums.nba-live.com/viewtopic.php?f=63&t=41809).

### Special moves

NBA Live 07 does not provide a useful controller tutorial, so these mechanics
are easy to miss:

- Flick the right stick to perform ordinary Freestyle dribble moves. More
  complex moves use half-circles rather than one direction.
- Hold the Freestyle Superstar modifier and move the right stick to perform a
  star's contextual special pass, shot or dunk. The result depends on the
  player's active ability, such as Playmaker, High Flyer or Outside Scorer.
- Hold the Freestyle Superstar modifier and click the right stick to cycle a
  multi-talented player's active Superstar ability. This also activates an
  available X-Factor state.
- Hold the right stick down while moving with the left stick to back down a
  defender. Holding the right stick up performs a pro-hop or power dribble.
- For a manual free throw, pull the right stick down to start the motion and
  push it up for the follow-through. Timing and keeping the stick centered
  affect accuracy. The ordinary shoot button can request a rating-based
  automatic attempt instead.
- Use the D-pad for four quick plays. Double-tapping a direction accesses the
  extended play-call behavior.
- The face buttons are contextual on defense: A switches players, X attempts a
  steal, Y blocks or rebounds, and B takes a charge.

### Clean exit

NBA Live 2005–08 can close its window while leaving the game process alive.
That also leaves Steam showing the game as Running. A shutdown trace confirmed
that NBA Live 07 entered Wine's loader cleanup and deadlocked instead of
reaching process exit.

`fix-clean-exit.sh` verifies the executable checksum, saves a reversible
backup beside it, and changes one branch in the game's CRT shutdown routine.
Normal shutdown then uses the executable's existing `TerminateProcess` path
after the main loop has returned. This is the primary fix for the verified
executable; it is not a background process killer. The player confirmed a
normal menu exit, and process inspection confirmed that the game and Proton
launch chain both ended.

## Quick commands

### 1. Install system tools and create the bottle

```bash
cd /path/to/game-compat
./install-system-packages.sh nba-live-07
./windows/nba-live-07/setup-bottle.sh
```

### 2. Prepare the installer

Copy the complete installation files to `C:\\Install\\NBA-Live-07` inside the
`nba-live-07` bottle. Repository scripts neither accept nor copy installation
files. Close the bottle, then run:

```bash
./windows/nba-live-07/fix-installer-directx.sh
```

Start the installer in Bottles and complete setup normally.

### 3. Configure and verify the runtime

```bash
./windows/nba-live-07/configure-runtime.sh
./windows/nba-live-07/verify-install.sh
```

### 4. Launch after runtime setup is completed

```bash
./windows/nba-live-07/launch.sh
```

The launcher warns before enabling automatic cleanup. Use `--yes` only after
reviewing that warning, such as in a deliberately configured Steam shortcut.
Use `--no-cleanup` to leave all bottle helpers running. Cleanup first requests
a normal bottle stop, then may use SIGTERM and a final SIGKILL fallback for a
stuck Bottles launcher.

### 5. Apply or remove the clean-exit repair

```bash
./windows/nba-live-07/fix-clean-exit.sh status
./windows/nba-live-07/fix-clean-exit.sh apply
./windows/nba-live-07/fix-clean-exit.sh rollback
```

The script refuses unknown executable builds and never overwrites its backup.

### 6. Install, inspect or remove the controller fix

```bash
./windows/nba-live-07/controller-fix/install.sh apply
./windows/nba-live-07/controller-fix/install.sh status
./windows/nba-live-07/controller-fix/install.sh rollback
```

Rebuilding is optional:

```bash
./windows/nba-live-07/controller-fix/build.sh
```

### 7. Create or refresh the Steam shortcut and artwork

This operation warns that Steam must close before its shortcut database is
edited. Confirm interactively, or pass `--yes` only when closing Steam is
acceptable:

```bash
./windows/nba-live-07/setup-steam.sh
```

The script downloads checksum-pinned cover and logo sources, generates Steam's
portrait, horizontal grid, hero, logo and icon sizes, and updates the single
`NBA Live 07` shortcut. It never assumes a Steam account or userdata path.

## Steam launch options

Steam integration is confirmed, but controller and presentation diagnostics
are still active. Keep the shortcut's generated command rather than copying a
machine-specific path from another computer. No additional user launch option
is recommended at this stage:

```text
%command%
```

## Notes for research

- The bundled DirectX engine logged the correct DirectX version followed by an
  unsupported-Windows result. Running it under Windows XP compatibility still
  failed because the bottle is 64-bit.
- Fresh Winetricks `d3dx9`, `d3dcompiler_43`, and `d3dcompiler_47` components
  are appropriate runtime dependencies, but installing them does not change
  the installer's separate obsolete operating-system check.
- The `hid:get_container_id_for_usb_udev_device` warning is associated with a
  Steam-created virtual Xbox controller that identifies as USB without having
  a physical USB parent. Device access from the Bottles Flatpak was verified;
  actual in-game input must still be tested before changing HID routing.
- The original executable reached the old CD check. The tested replacement
  executable opened the game window, proving that the protection check was the
  remaining startup blocker after repairing WineD3D.
- The current widescreen plugin v1.04 was released on 2024-06-09. It uses a
  configurable `RES_X`/`RES_Y` pair and includes corrected widescreen assets.
- Bottles' GE-Proton runner left `explorer.exe /desktop` alive after the game
  executable closed. Four accumulated launch processes were observed. The
  updated launcher was verified to detect the real game exit, stop this bottle,
  return normally, and leave no NBA game, Wine desktop, or Bottles launch
  process behind.
- A normal menu exit closed the visible window but left `nbalive07.exe`
  deadlocked in loader cleanup. The clean-exit binary patch was then confirmed
  to close the game process, Proton chain, Overlay helper, and Steam Running
  state without a wrapper kill.
- Community control references agree that the current-generation game uses the
  left stick for movement and the right stick for Total Freestyle Control. They
  also document advanced right-stick half-circles, right-stick down/up free
  throws, A/pass, B/shoot, X/layup, Y/dunk and contextual defensive actions.
- One controller test ended with a null dereference at `0x0080b10b` while NBA
  was tearing down an internal object. A repeat using the fully instrumented
  controller module loaded the same mappings and returned to the main menu
  without a crash, so the crash is not reproducible and is not attributed to
  the controller fix.

### Technical details

<details>
<summary>Controller lookup, binding evidence and safety checks</summary>

Wine delivered changing DirectInput reports from three separate controller
interfaces. NBA enumerated them in gameplay slots 3, 4 and 5, but
`FUN_006588d0` returned no profile for the modern Wine device names. Passing
that null result to `FUN_0065fc90` caused the native loader to do nothing.

The ASI detours the exact-name lookup at `0x006588d0`, calls the original first,
and falls back to `XboxWiredGamepad.jfg` only for otherwise unknown controller
names. NBA's unmodified loader at `0x0065fc90` and binder at `0x00659670` then
created 18 of 18 bindings for each gameplay controller: four D-pad directions,
ten digital buttons and four stick axes. The same run logged no failed gameplay
binds.

The module supports only the executable SHA-256 documented under `Tested with`.
It verifies the fixed image base, original instruction bytes and bundled profile
before installing a detour. A mismatch is logged and refused. The build fixes
neutral linker metadata so rebuilding the checked-in source produces a stable
binary hash.

The checked-in deterministic ASI has SHA-256
`12745345aef0cb92c44fd944ae75646a5be536c1d3e0fdf3d74cee01322db7e6`.

</details>

## TODO (not yet fixed)

- Apply the matching North American English official update.
- Apply the North American English DVD-ROM official update, then install and
  checksum-compare the NLSC 1.1 fixed executable. The currently working
  replacement bypasses the CD check but is incompatible with Resolution v1.04.
- Install FIFAM ASI Loader and NBA Live Resolution v1.04, then verify the
  active resolution and aspect ratio on the current display.
- LT and RT are not used by EA's bundled DirectInput profile. A future optional
  mapping may expose them without replacing or duplicating confirmed actions.
- Finish the Steam controller and Alt-Tab tests. Steam launch, Overlay, and
  clean shutdown are confirmed.
