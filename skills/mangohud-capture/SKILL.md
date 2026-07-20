---
name: mangohud-capture
description: Configure, run, and validate bounded MangoHud telemetry for Linux games. Use when diagnosing FPS, frame time, CPU/GPU utilization, clocks, power, VRAM, renderer, present mode, or when a MangoHud log is missing or malformed.
---

# MangoHud capture

1. Resolve the game case directory from the repository, never from the caller's working directory.
2. Create an ignored run directory under `<case>/logs/mangohud/` before launch.
3. Put `MANGOHUD=1` and `MANGOHUD_CONFIG` before `%command%`.
4. Use an absolute, writable `output_folder` with no accidental whitespace.
5. Log without an FPS limiter unless the single variable under test is the limiter.
6. Bound unattended logging with `log_duration` and observe for 60–120 seconds by default.
7. Capture `nvidia-smi` or the platform-equivalent telemetry independently when GPU behavior matters.
8. Confirm a non-empty MangoHud CSV was created; never infer success from the overlay alone.

Recommended fields:

```text
fps,frametime,frame_timing,gpu_stats,gpu_temp,gpu_core_clock,gpu_power,cpu_stats,cpu_temp,ram,vram,engine_version,vulkan_driver,present_mode,display_server,refresh_rate,autostart_log=1,log_duration=120,output_folder=/absolute/case/logs/mangohud
```

Always report the complete copy-paste Steam launch-options line. Keep raw logs ignored and move only durable conclusions into the game's `RESULTS.md`.
