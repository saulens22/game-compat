# Assassin's Creed Freedom Cry

Steam App ID `277590`. This profile keeps the game’s native controller route,
uses its highest useful image settings at the current resolution, and removes
motion blur without adding a frame limiter or wrapper.

## Tested with

- Environment: [shared tested environment](../../TESTED_ENVIRONMENT.md), snapshot dated 2026-07-20.
- Steam standalone edition, build `11262618`; live `ACFC.exe` through DXVK D3D11.
- GE-Proton11-1 via the `Proton-GE Latest` compatibility-tool mapping.
- KDE Wayland and normal desktop Steam; Big Picture Mode was not assumed.
- Steam’s unchanged default Xbox-controller route; no community layout was selected.
- 3840x2160 at 60 Hz, NVIDIA driver `610.43.03`, maximum native quality, SMAA, and motion blur off.

## Default behavior

- First launch installs Ubisoft Connect, displays the Steam product-key notice,
  and may take several minutes before the game window appears.
- The generated profile defaults to High rather than Very High for environment
  and shadows, FXAA, SSAO, Low god rays, and enabled motion blur.
- Ubisoft Connect may remain in the notification area after the game exits,
  keeping Steam’s session marked as running.

## Final behavior

- The verified live executable is `ACFC.exe`, using DXVK’s D3D11 path at native 4K.
- Environment and shadows are Very High; textures and reflections are at their
  available High maximum; volumetric fog and High god rays remain enabled.
- SMAA replaces blurrier FXAA/TXAA, HBAO+ High replaces SSAO, and motion blur is off.
- VSync remains enabled, but no external FPS limiter is installed. The observed
  title/menu path was GPU-bound around 48–57 FPS at these settings.
- Resolution and refresh rate remain player-controlled and are never hard-coded by the scripts.

## Fixes required to reach it

No binary mod, controller layout, external player, or launch wrapper is needed.
The installer edits only the game-generated graphics keys. SMAA was selected
because it preserves a sharper 4K image than TXAA while avoiding FXAA’s softer
edge treatment. Motion blur is disabled as an image preference, not as a
performance reduction.

`Proton-GE Latest` is pinned through the repository’s safe App-ID-scoped helper.
The setup fingerprints Steam controller configuration before and after setup so
it cannot silently install or select a community mapping.

## Quick commands

Apply the complete profile after launching and exiting the game once:

```bash
cd /path/to/game-compat
# Exit Steam before the next command.
./steam/assassins-creed-freedom-cry-277590/setup-steam.sh
```

Verify without changing the installation:

```bash
./steam/assassins-creed-freedom-cry-277590/verify-install.sh
```

Restore the original configuration and previous Steam launch options:

```bash
./steam/assassins-creed-freedom-cry-277590/rollback-fixes.sh
```

Rollback asks for confirmation. `--yes` is available for deliberate
non-interactive use. These scripts never kill Steam, Ubisoft Connect, or the game.

## Steam launch options

No custom launch option is recommended. Use this complete replacement line:

```text
%command%
```

## Notes for research

- The real executable, D3D11 renderer, exact generated values, and clean config
  write were verified rather than inferred from Steam’s play state.
- The adjusted values were first applied in the game UI and persisted after a
  normal in-game exit. The scripts reproduce those same numeric values without
  changing `DisplayWidth`, `DisplayHeight`, or refresh-rate keys.
- The performance overlay seen during research came from the tester’s global
  environment; it is not installed or enabled by this profile.
- Ubisoft authenticated automatically for this App ID and cloud synchronization
  completed. No credential was read, stored, or automated.
- No HD texture pack or executable patch was installed: the native D3D11 image
  path already exposes appropriate 4K rendering and the desired settings.

### Game links

- [Steam store](https://store.steampowered.com/app/277590/)
- [Steam Community](https://steamcommunity.com/app/277590)
- [ProtonDB](https://www.protondb.com/app/277590)
- [SteamDB](https://steamdb.info/app/277590/)

### Fix and project links

- [Proton](https://github.com/ValveSoftware/Proton)
- [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Assassin%27s_Creed%3A_Freedom_Cry)

## TODO (not yet fixed)

- Confirm every gameplay action and prompt with a physical Xbox controller in a
  representative mission; Steam preserved the default route, but this pass did
  not claim a player-confirmed full control test.
- Confirm that choosing **Quit** from Ubisoft Connect’s tray menu ends the
  lingering post-game session while retaining remembered authentication.
