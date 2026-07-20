# Kelyje II case guidance

- Use Bottles only, with the canonical win64 `kelyje-2` bottle and GE-Proton
  11-1. Never create a raw Wine prefix or publish a win32 migration path.
- Controller support is out of scope unless the user explicitly changes that requirement.
- Do not create a host mount. The verified self-contained `TRUCK.INI` paths are the accepted route.
- Do not rerun the game installer over an existing installation. Use `configure-fixes.sh` for repair.
- Installation is a separate user step. Scripts must not accept, locate, extract, copy, mount, or archive installation files.
- Preserve the Lithuanian 7.3 executable and resources. Do not install 8.x/1.x resource packs over them.
- Do not automate gameplay. Bounded launch-to-menu observation is sufficient.
- Treat the live registry (`CurrentVersion 5.1`) as authoritative when Bottles 64.1 leaves a stale Windows value in `bottle.yml`.
- Steam integration is optional. Its direct shortcut must retain
  `ddraw=n,b;ir50_32=n,b`, use the stable shared-prefix state directory, and be
  the only Kelyje II shortcut. Launch diagnostics with the full 64-bit shortcut
  game ID; `steam -applaunch` misparses this shortcut's high unsigned App ID.
