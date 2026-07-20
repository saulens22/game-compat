# Game compatibility research workspace

## Layout

- Keep Steam games in `<repo>/steam/<game-slug>-<app-id>/`. Use a separate
  `windows/<game-slug>/` folder for non-Steam Windows/Wine games. Organize
  emulation by system at `emulators/<system>/`; keep that system's documented
  games and helpers directly inside it rather than creating per-game folders.
  Emulator frontends belong in `emulators/frontends/<frontend>/`, even when the
  frontend itself is distributed through Steam. Record its Steam App ID in
  documentation, not in the frontend folder name.
- Put ad-hoc agent scripts, temporary audits, and cross-case verification tools
  in ignored `<repo>/_work/`; do not commit them.
- Never mix logs, settings, conclusions, or experiments from different games.
- Each game directory should contain a `README.md` case file and may contain
  `logs/`, `evidence/`, and game-specific helper scripts.
- Keep copies of discovered game configuration files under that game's
  `configs/` directory. Use the Steam diagnostic skill's
  `scripts/game-config-snapshot.sh` for
  verified backups/restores when possible; snapshot before changing a config.
- Put reusable shared tooling in `<repo>/skills/` or at repository root. Keep
  game-specific scripts inside that game's directory.

## Published case documentation

- Write each game `README.md` for a player, not for an agent. Put operational
  instructions for Codex or other agents in that case's `AGENTS.md`.
- Every game README must contain these sections in this order:
  `Tested with`, `Default behavior`, `Final behavior`, `Fixes required to reach
  it`, `Quick commands`, `Steam launch options`, `Notes for research`, and
  `TODO (not yet fixed)`.
- Every game has `versions.json`. Increment `current` whenever published scripts
  or their behavior change, preserve earlier history entries, and summarize the
  user-visible difference. The helper app and Pages derive version UI from this
  file; never hard-code a game or version in the launcher.
- Under `Tested with`, link to the sanitized shared environment snapshot and
  list the exact game edition, executable/renderer variants, compatibility-tool
  builds, input path, and other game-specific variables actually tested. Never
  imply that the current package snapshot applied to an older run when versions
  differed; record the historical version on the game page.
- Put install, verify, rollback, and diagnostic commands in fenced, copyable
  blocks under `Quick commands`. Put the complete Steam launch-options
  replacement line in its own fenced block; if no custom line is recommended,
  say so explicitly and show `%command%`.
- Explain why every non-obvious fix, wrapper, compatibility tool, or external
  player is used. Include enough test history to show which simpler approaches
  failed and why the final route was selected.
- Clearly distinguish a working fix from diagnostic tooling. If no fix was
  found, say so at the start and summarize the tested alternatives and measured
  result rather than presenting the diagnostic runner as a solution.
- Keep `RESULTS.md` limited to sanitized final conclusions. Keep partial audits,
  raw logs, screenshots, machine paths, and intermediate evidence in ignored
  local directories.
- Published downloads must be goal-oriented: provide one complete case bundle,
  a copyable primary command, and a short explanation for every individual
  helper. Do not publish an unexplained filename list.
- Published Steam game pages must include App-ID-derived links to the official
  Steam store and Community hub plus ProtonDB and SteamDB. Keep these under
  `Game links`, separate from mod, fix, decompilation, and tool repositories
  under `Fix and project links`.
- Keep generated Pages navigation to one collapsible platform level: `Steam →
  Game`, `Windows → Game`, or an emulator-system group. Never recreate the old
  redundant `Games → Steam → Game` hierarchy. Show the Steam App ID in each
  Steam game's menu label.
- During active research, do not run the MkDocs/Pages build locally and do not
  commit, push, or deploy incremental findings. Publish GitHub Pages only after the user
  confirms the research result, using one concluding commit where practical.
  Push that concluding commit to `main`; the Pages workflow deploys every push
  to `main` automatically. Pull requests run checks without deploying.

## Starting and testing another game

- Treat every game as a new case. Do not inherit GTA III's Big Picture Mode,
  controller, intro-video, mpv, ASI-loader, renderer, display, or launch-wrapper
  assumptions.
- For every non-Steam Windows game, use Bottles with exactly one bottle per
  game. Never substitute an ad-hoc raw Wine prefix. Keep Bottles frontend and
  runner details in the case evidence, and launch the registered Bottles program
  from Steam through a repository wrapper when Steam integration is requested.
- Start from the launch path the user actually intends to use. If none is
  specified, establish a stock normal Steam Play or direct executable baseline;
  do not assume Big Picture Mode. Test Big Picture separately only when the user
  requests it, and claim support only after that exact path passes.
- Read the case README, final results, local experiment ledger, and available
  evidence before testing. Search for the same effective signature and do not
  repeat it without a changed external condition and recorded justification.
- Capture a read-only baseline before installing fixes: live executable,
  compatibility tool, process tree, renderer, visible window identity, launch
  options, controller mapping, overlay state, display/session, and relevant
  configuration fingerprint.
- Reproduce the user's symptom through the real launch path before changing
  anything. Then isolate one layer or variable per run: stock game, compatibility
  tool, loader, fix/plugin, media wrapper, controller mapping, or presentation.
- Never select a Workshop/community controller layout as a convenience. Preserve
  the user's current/default mapping, fingerprint it around setup, and test
  controller behavior only when controller support is in scope.
- Verify the executable and loaded modules after launch. A selected Steam menu
  item, intended renderer, or configured plugin is not proof that it is active.
- Keep game-specific packages, scripts, logs, conclusions, downloads, and TODOs
  inside that game's case. Promote tooling to shared scope only after it is
  genuinely useful across multiple cases.
- Record failed approaches with their visible result and why they were rejected.
  Document a final behavior only after the user confirms it or objective evidence
  fully establishes it; label untested integrations explicitly.
- Any published script that stops or kills Steam, a game, Wine, Proton, or a
  managed service must warn before launch and require interactive confirmation.
  Provide `--yes` for deliberate non-interactive operation. Bounded diagnostics
  that normally terminate a game must also provide `--no-stop` (or an equivalent
  clearly named flag) to leave it running. Document possible SIGKILL fallback.

## Working method

- Begin by reading the game's `README.md` and existing evidence.
- Separate observed facts from hypotheses and clearly timestamp live state.
- Prefer read-only inspection before changing Steam, Proton, display, driver,
  prefix, or game settings.
- Record every launch option exactly, including whether variables appear before
  `%command%`.
- Never edit Steam compatibility-tool mappings directly. While Steam is stopped,
  use `<repo>/set-steam-compat-tool.sh` so the App ID is scoped,
  backed up, and verified.
- Preserve online-required settings and save data. Ask before deleting or
  recreating a Proton prefix.
- Avoid Gamescope unless the game's case file says it is known-good. Nested
  Gamescope can introduce a separate compositor failure and obscure the game bug.
- Do not infer the active renderer from a selected Steam menu entry alone; verify
  the actual executable and process.
- After a test, capture the result and update the case file so a restarted Codex
  session does not repeat failed experiments.
- Before every mutating or launch experiment, search the game's README and
  experiment ledger for the same effective variables and outcome. Do not repeat
  an experiment merely to reconfirm it. A deliberate repeat requires a stated
  reason and a genuinely changed condition (for example a package update).
- Give each experiment a canonical signature containing the compatibility tool,
  renderer, complete launch-options line, relevant game settings, display state,
  and the single variable under test. Use the shared experiment guard when
  available; record the signature and result immediately after the run.
- Include the `game-config-snapshot.sh fingerprint` value in experiment
  signatures. Treat exit status 10 from either config snapshots or the
  experiment guard as a duplicate and do not launch unless a changed external
  condition and repeat justification are explicitly recorded.

## Useful read-only tools

- Display/session: `kscreen-doctor -o`, `xrandr --current`, `loginctl`, `findmnt`
- GPU/driver: `vulkaninfo --summary`, `nvidia-smi`, `nvidia-smi dmon`, `lspci -k`
- Processes: `ps`, `/proc/<pid>/environ`, `/proc/<pid>/cmdline`
- Logs: `journalctl`, `coredumpctl`, Steam `console-linux.txt` and `compat_log.txt`
- Search/config: `rg`, `find`, `strings`
- Frame diagnostics: MangoHud logging without an FPS limiter
- Proton: `PROTON_LOG=1` and renderer-specific debug logging

## Default compatibility tool

- When `Proton-GE Latest` is installed, treat it as the default Steam
  compatibility tool for game cases unless a case file explicitly requires a
  different known-good default.
- Selecting an older, official, Experimental, or distribution Proton build for
  diagnosis is temporary. Record the selected build and isolated prefix, then
  restore the game's Steam compatibility mapping to `Proton-GE Latest` when the
  test is finished.
- Do not leave a game pinned to a diagnostic Proton build merely because it was
  the most recently tested tool.
