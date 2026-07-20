# Non-Steam Windows games

Store each non-Steam Windows/Wine game in `windows/<game-slug>/`.

All Windows cases use the officially supported Bottles Flatpak for isolation,
including games ultimately launched from Steam. Native/community Bottles
packages are not supported by this repository. Create exactly one stable,
lowercase bottle per game. Do not create ad-hoc raw Wine prefixes. Shared
automation lives in `bottles-game.sh`; each case should wrap it with fixed
bottle and program names rather than duplicating Bottles discovery logic.

Treat the game installer and the compatibility environment as separate phases.
The player first copies and runs their installation files inside the dedicated
bottle. Tracked fix scripts must never accept, locate, copy, extract, mount, or
archive those files. After installation, each per-game setup script selects its
final runner and installs every verified runtime dependency itself through
`bottles-winetricks.sh`; do not trust legacy installers to finish DirectX,
codec, Visual C++ or other redistributable setup correctly.

The shared manager supports these case-independent operations:

```bash
./bottles-game.sh status
./bottles-game.sh list
./bottles-game.sh ensure game-slug win64 gaming
./bottles-game.sh config game-slug
./bottles-game.sh fingerprint game-slug
./bottles-game.sh snapshot game-slug _work/game-slug-before-change.tar.zst
./bottles-game.sh add game-slug 'Game name' 'C:\Games\Game\Game.exe'
./bottles-game.sh run game-slug 'Game name'
./bottles-game.sh stop game-slug
```

`win64` is the default and supports both 64-bit applications and most 32-bit
games through Wine WoW64. Use an explicit `win32` bottle only when a game case
has a verified pure-32-bit requirement. Bottle architecture cannot be converted
after creation; create a separate bottle for architecture experiments.

`stop` uses Bottles' configured Wine runner and `wineboot -k` for that one
bottle. It warns about unsaved data and asks for confirmation; `--yes` is the
explicit non-interactive override. It does not stop Steam or other bottles.

Snapshots refuse to run while a process exposes that bottle as its Wine prefix,
never overwrite an existing archive, and produce a separate SHA-256 file. The
manager deliberately has no delete command: removing a bottle is destructive
and belongs in a game-specific, backup-aware workflow.

Steam integration is optional and must never be assumed. A normal Bottles
launch remains the baseline. Cases that explicitly verify direct Steam
integration may use `add-bottles-steam-shortcut.sh` to let Steam Proton share a
win64 Bottles prefix. This can restore Steam Overlay for games whose Flatpak
wrapper path cannot provide it, but it is brittle because both tools can update
the same prefix. Snapshot first, retain only one shortcut per game, and preserve
every game-specific DLL override in the complete launch-options line.

Each case should contain:

- `README.md` for user-facing setup and reproduction.
- `RESULTS.md` for sanitized final findings only.
- `AGENTS.md` only when game-specific diagnostic procedure is needed.
- `requirements.txt` with optional `# selectors:` aliases.

Keep prefixes, logs, captures, configuration snapshots, downloaded installers,
and other machine-specific state in the standard ignored directories.

The shared `windows/requirements.txt` manifest installs only safe user-space
NRG-to-ISO conversion and ISO inspection tools. It deliberately does not install
CDEmu or VHBA: VHBA is coupled to the running kernel and a generic dependency
transaction can replace or reinstall kernel packages. Add optical-drive
emulation manually only for a specific case after reviewing the active kernel,
matching module provider, rollback, and reboot implications.
