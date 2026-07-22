# NBA Live 07 controller profile fallback

NBA Live 07 receives modern Xbox-family controllers through DirectInput but
looks up controller profiles by an exact device name. Modern Wine names are not
present in the game's registry, so the game loads no bindings despite receiving
valid input reports.

This ASI calls NBA's original lookup first. It changes behavior only when that
lookup returns no profile for a controller, returning the game's bundled
`XboxWiredGamepad.jfg`. NBA's own profile executor and binder then create the
normal mappings. Keyboard handling and recognized controller profiles remain
unchanged.

The module is specific to the executable hash checked by `install.sh`. It also
verifies the expected machine code and bundled profile at runtime; a mismatch
is logged and refused instead of patched blindly.

The checked-in reproducible binary SHA-256 is
`12745345aef0cb92c44fd944ae75646a5be536c1d3e0fdf3d74cee01322db7e6`.

Build, install, inspect, or remove it from any working directory:

```bash
/path/to/game-compat/windows/nba-live-07/controller-fix/build.sh
/path/to/game-compat/windows/nba-live-07/controller-fix/install.sh apply
/path/to/game-compat/windows/nba-live-07/controller-fix/install.sh status
/path/to/game-compat/windows/nba-live-07/controller-fix/install.sh rollback
```

The log is written beside the plugin as
`plugins/nba-controller-profile-fallback.log`. It lists the selected profile,
every native action/input bind result, and each controller's binding count.
