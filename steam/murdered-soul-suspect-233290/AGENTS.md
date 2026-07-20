# Murdered: Soul Suspect App ID 233290 research notes

- Never replace or recreate the prefix to address the receipt bug.
- Treat `FATEGAME.SAV`, `profile.bin`, and `remotecache.vdf` as one rollback unit.
- Never patch while Steam or `Murdered.exe` is running.
- Verify live `Binaries/Win64/Murdered.exe` and DXVK; WineD3D is a ruled-out renderer experiment.
- Do not navigate or play the game for the user. In-game validation is player-operated.
- The receipt marker must occur exactly once and have the expected surrounding bytes.
- Require `sq_carnage_crash`, `sq_carnage_plate`, and `sq_carnage_scotch` to
  occur exactly once and already be `01 01`; otherwise refuse the receipt repair.
- Do not hard-code a byte offset: checkpoint serialization moves the record between saves.
