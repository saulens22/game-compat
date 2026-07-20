# MK11 agent instructions

- Verify the live executable after every launch; do not infer it from Steam's selected entry.
- Preserve `FrameSkip = 1` unless the user explicitly accepts losing online play.
- When GPU behavior is under test, collect independent GPU telemetry in addition to MangoHud because the recorded failure included low utilization.
- Restore `Proton-GE Latest` after any temporary MK11 compatibility-tool comparison.
