# Need for Speed: Most Wanted Black Edition case guidance

- Use only the canonical win64 `nfsmw-black-edition` Bottles bottle. Never use
  a raw Wine prefix, create a win32 precursor, or publish a migration workflow.
  Architecture experiments belong only in ignored `_work/` evidence.
- Installation is a separate user step. Scripts must not accept, locate, copy,
  extract, mount, or archive installation files.
- Do not keep `NFSMW2005_widescreen_fix.asi` and
  `NFSMostWanted.WidescreenFix.asi` active together; upstream confirms that
  duplicate generations can crash the game.
- Do not hard-code a display resolution. Set `g_RacingResolution` to the
  Widescreen Fix auto-detection sentinel immediately before launch.
- Do not automate gameplay or GUI input. The player performs acceptance tests.
- Xbox controller support is player-confirmed through Steam and the Widescreen
  Fix. Preserve the player's current/default Steam layout and in-game remap;
  XtendedInput was researched but deliberately not installed.
- Do not claim NT sync is working merely because the kernel device exists.
  Require both `ntsync: up and running` and a player-confirmed game launch.
- Keep the confirmed Xbox 360 Stuff plus HD Reflections stack optional. Most
  Wanted HQ changes game data and may affect saves; never layer it over this
  setup or an existing profile automatically.
