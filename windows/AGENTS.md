# Non-Steam Windows case instructions

- Steam tracks the entire shortcut command. Never run Bottles CLI, Wine,
  wineserver, Proton, Steam, `wineboot`, Winetricks, dependency installation or
  runner configuration from a normal Steam launch-options preamble.
- Apply persistent prefix configuration during setup. For a DWORD that must be
  reset on every launch, use the repository's offline
  `wine-reg-set-dword.sh` helper and verify that the bottle is inactive first.
- Every allowed pre-launch helper must be deterministic, non-interactive and
  bounded. `add-bottles-steam-shortcut.sh` supplies the standard ten-second
  timeout; do not bypass it in a per-game setup script.
- If Steam remains on **Running** after the visible game exits, verify that the
  real executable is absent. Inspect Steam's tracked launch root and processes
  with the game's `WINEPREFIX`; stop only the named bottle, then send `SIGTERM`
  only to the remaining per-game launch roots. Do not restart Steam or kill all
  Wine processes as the first response.
- Record the executable, stale helper, elapsed lifetime, Steam App ID, recovery
  method and wrapper correction in the game's research notes. Do not publish
  machine-specific PIDs or paths.
