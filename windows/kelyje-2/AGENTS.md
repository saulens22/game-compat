# Kelyje II case guidance

- Use Bottles only, with the existing `kelyje-2` bottle. Never create a raw Wine prefix.
- Controller support is out of scope unless the user explicitly changes that requirement.
- Do not create a host mount. The verified self-contained `TRUCK.INI` paths are the accepted route.
- Do not rerun the game installer over an existing installation. Use `configure-fixes.sh` for repair.
- Preserve the Lithuanian 7.3 executable and resources. Do not install 8.x/1.x resource packs over them.
- Do not automate gameplay. Bounded launch-to-menu observation is sufficient.
- Treat the live registry (`CurrentVersion 5.1`) as authoritative when Bottles 64.1 leaves a stale Windows value in `bottle.yml`.
