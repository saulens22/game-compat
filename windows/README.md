# Non-Steam Windows games

Store each non-Steam Windows/Wine game in `windows/<game-slug>/`.

All Windows cases use Bottles for isolation, including games ultimately launched
from Steam. Create exactly one stable, lowercase bottle per game. Do not create
ad-hoc raw Wine prefixes. Shared automation lives in `bottles-game.sh`; each
case should wrap it with fixed bottle and program names rather than duplicating
Bottles discovery logic.

The shared manager supports these case-independent operations:

```bash
./bottles-game.sh status
./bottles-game.sh list
./bottles-game.sh ensure game-slug win32 gaming
./bottles-game.sh config game-slug
./bottles-game.sh fingerprint game-slug
./bottles-game.sh snapshot game-slug _work/game-slug-before-change.tar.zst
./bottles-game.sh add game-slug 'Game name' 'C:\Games\Game\Game.exe'
./bottles-game.sh run game-slug 'Game name'
```

Snapshots refuse to run while a process exposes that bottle as its Wine prefix,
never overwrite an existing archive, and produce a separate SHA-256 file. The
manager deliberately has no delete command: removing a bottle is destructive
and belongs in a game-specific, backup-aware workflow.

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
