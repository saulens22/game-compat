# Windows compatibility tools

This section explains reusable tools that can help older Windows games run on
Linux. These pages do not redistribute third-party programs. Download tools
from their official project pages, follow the upstream license, and keep each
game's files inside that game's own Wine or Bottles environment.

Start with the game's own guide. A compatibility tool should address an
observed problem, not be installed pre-emptively. In particular, input wrappers
can expose duplicate controllers or replace an API that already works.

## Available guides

- [Xidi](xidi/README.md) converts XInput controllers into legacy DirectInput or
  WinMM controllers for older games.
