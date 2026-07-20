---
name: steam-proton-diagnostic
description: Diagnose Steam games under Proton with bounded one-variable experiments, executable verification, configuration snapshots, and durable results. Use for launch failures, renderer selection, compatibility-tool comparisons, controller/Overlay behavior, crashes, or low FPS.
---

# Steam and Proton diagnostic

1. Read the game's `README.md`, `RESULTS.md`, and applicable `AGENTS.md` files.
2. Inspect live processes and current Steam launch options before mutation.
3. Snapshot relevant settings with `scripts/game-config-snapshot.sh` and include its fingerprint in the experiment signature.
4. Check `scripts/experiment-guard.sh` before launching; do not repeat an identical signature without a changed external condition and recorded justification.
5. Change one effective variable at a time. Preserve saves, controller layouts, online-required settings, and prefixes.
6. Launch through the real Steam path. Verify the actual executable, renderer, compatibility tool, Overlay, and controller state from live evidence.
7. Observe unattended runs for 60–120 seconds unless startup requires a documented longer warmup.
8. Stop only the game's process tree after the bounded run.
9. Store raw logs, screenshots, snapshots, prefixes, and experiment ledgers in ignored local directories.
10. Write only sanitized durable conclusions to `RESULTS.md`; keep agent procedure in `AGENTS.md`.

Always provide the complete launch-options replacement line, with environment variables before `%command%`. Resolve bundled scripts from this `SKILL.md` directory; do not depend on the shell's current directory. Use `scripts/steam-session.sh` for a managed client and `scripts/summarize-diagnostic.sh` for standard telemetry.
