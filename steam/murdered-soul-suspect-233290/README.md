# Murdered: Soul Suspect

Steam App ID `233290`. The game runs normally through Proton, but the tested save
encountered the cross-platform **Near Gas Station** receipt-state bug. This case
provides a guarded, reversible repair that leaves one legitimate clue available
so the game can run its own investigation transition.

## Tested with

- Environment: [shared tested environment](../../TESTED_ENVIRONMENT.md).
- Steam edition, build `270764`; verified live executable `Binaries/Win64/Murdered.exe`.
- GE-Proton11-1 through `Proton-GE Latest`, DXVK D3D11, KDE Wayland, and normal desktop Steam.
- Stock Steam launch options and the default Xbox-controller configuration.
- Existing Steam Cloud checkpoint at the Salem hub after the police-station sequence.

## Default behavior

- The game launches and plays correctly with DXVK.
- In the affected save, **Near Gas Station** contains Gruesome Car Crash, B-RAD,
  and Scotch Whiskey, but the SOC Gas Station Receipt cannot be inspected.
- Switching to WineD3D does not repair the quest and produces graphical glitches.
- Loading a checkpoint updates the save automatically; there is only one active
  checkpoint slot, so replacing or experimenting without a complete backup is risky.

## Final behavior

- The checkpoint, profile, and Steam Cloud metadata are backed up as one unit.
- The stuck receipt is marked found/reviewed (`01 01`) with all three badge
  marks, while B-RAD is reset to uncollected (`00 00`) with zero badges. The
  player can then collect B-RAD again in game, making the game itself process
  the transition from 3/4 to 4/4.
- The repair does not change location, story progress, collected artifacts,
  controller settings, renderer, compatibility tool, or graphics configuration.
- The corrected v3 transition repair still requires in-game confirmation after
  B-RAD is recollected.

## Fixes required to reach it

The receipt bug also exists on PlayStation 4, so it is a shipped quest-state bug
rather than a Linux graphics-translation fault. Local analysis found the first
three clue records in `01 01` state and only `sq_carnage_receipt` in `00 00`.
An isolated completed PC reference save independently uses `01 01` for the receipt
and all remaining Carnage clues.

`repair-receipt-save.sh` first requires Gruesome Car Crash, B-RAD, and Scotch
Whiskey to exist exactly once in the completed `01 01` state. It then marks the
receipt complete and resets B-RAD, refuses ambiguous or unexpected data, creates
a three-file backup, patches a temporary copy, and accepts only the expected
two- or four-byte delta. It never kills Steam or the game; both must already be
closed.

The earlier v2 repair marked only the receipt complete. That made the journal
show 4/4, but its three rating badges stayed blue/unfilled because no clue was
collected inside the running level to trigger the scripted transition. Version
v4 gives the receipt the verified three-badge value and fully clears both
B-RAD's collected flags and badge value before the player recollects it.

## Quick commands

Apply the guarded transition repair after exiting the game and Steam:

```bash
./steam/murdered-soul-suspect-233290/repair-receipt-save.sh
```

Verify that the receipt is complete and B-RAD is available again:

```bash
./steam/murdered-soul-suspect-233290/verify-receipt-save.sh
```

Restore the complete pre-repair checkpoint, profile, and Cloud metadata:

```bash
./steam/murdered-soul-suspect-233290/rollback-receipt-save.sh
```

Repair and rollback require interactive confirmation. `--yes` is available for
deliberate non-interactive operation. Neither script stops Steam or the game.

## Steam launch options

No custom launch option is required. Use this complete replacement line:

```text
%command%
```

Do not use `PROTON_USE_WINED3D=1 %command%` for the receipt bug. It changes only
the graphics backend and caused visual corruption without changing quest state.

## Notes for research

### Known bugs and solutions

| Symptom | Finding | Recommended response |
| --- | --- | --- |
| SOC receipt cannot be inspected | Cross-platform side-case state bug; reproduced by other players on PS4 | Use v3 to mark the receipt complete, reset B-RAD, then recollect B-RAD so the game runs the transition |
| WineD3D graphical corruption | OpenGL renderer regression, unrelated to quest data | Restore `%command%` and use DXVK |
| Save apparently disappears or an older save returns | Steam Cloud/local checkpoint disagreement has been reported | Back up checkpoint, profile, and `remotecache.vdf` together before repair |
| Locked out of earlier areas near the ending | The museum/Judgment House sequence has a point of no return | Finish optional cases and collectibles before advancing |
| Gameplay breaks above 60 FPS | Unreal Engine timing can malfunction at excessive frame rates | Keep the game at 60 FPS or below; do not use an uncapped configuration |

The receipt is clue 4/4 beside the crashed car, beyond the hedge/opening. It is
not one of the later clues at the fuel pumps. Investigation clues do not count
toward the 242 artifact total, but completing the side case unlocks **Carnage**.
The v2 repair made the clue visible without running the normal in-level
transition: the journal showed 4/4 while its three badge marks stayed unfilled.
The corrected v3 approach reopens B-RAD so the game can run a genuine clue event
instead of trying to reconstruct the larger investigation state.

### Game links

- [Steam store](https://store.steampowered.com/app/233290/)
- [Steam Community](https://steamcommunity.com/app/233290)
- [ProtonDB](https://www.protondb.com/app/233290)
- [SteamDB](https://steamdb.info/app/233290/)

### Fix and project links

- [Proton](https://github.com/ValveSoftware/Proton)
- [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Murdered%3A_Soul_Suspect)
- [Receipt bug reported on PS4](https://gamefaqs.gamespot.com/boards/691087-playstation-4/73242047)
- [Near Gas Station walkthrough](https://gamefaqs.gamespot.com/pc/703517-murdered-soul-suspect/faqs/69443/salem-from-the-church)

## TODO (not yet fixed)

- Recollect B-RAD after applying v3 and confirm that the next clue set appears.
- Complete the side case and confirm that **Carnage** unlocks normally.
