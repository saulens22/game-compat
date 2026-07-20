# Emulated games and systems

The repository unit is the emulated system, not each game. Keep documentation
and descriptively named game helpers directly in `emulators/<system>/`:

```text
emulators/gba/
emulators/ps2/
emulators/switch/
```

Each system has one player-facing `README.md`, sanitized `RESULTS.md` when tests
exist, optional agent-only `AGENTS.md`, and `requirements.txt`. Add per-game
sections and clearly named scripts inside that system folder instead of another
directory level.

Frontend documentation is separate at `emulators/frontends/<frontend>/`.
RetroArch remains there even when the tested binary is Steam App ID `1118310`;
Steam is its distribution/launch path, not its place in this repository's
taxonomy.

The separate private content library uses:

```text
$EMULATION_ROOT/roms/<system>/<local game files>
```

For example, the Radical Red research and scripts live in `emulators/gba/`,
while its locally patched ROM lives under
`$EMULATION_ROOT/roms/gba/`. This separation keeps copyrighted content and live
saves out of Git while keeping the setup reproducible.

RetroArch is one frontend, not the owner of this hierarchy. Systems better
served by standalone emulators still use the same system directory. Reserved
folders such as `roms/switch` and `roms/ps5` only provide stable organization;
they do not claim that a RetroArch core exists or that the platform is currently
playable. Standalone emulator research still belongs under the corresponding
`emulators/<system>/` group. The shared system catalog is `emulators/systems.txt`.

Do not commit ROMs, BIOS files, saves, memory cards, shader caches, screenshots,
logs, or any other copyrighted or machine-specific artifacts.
