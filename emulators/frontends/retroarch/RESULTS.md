# RetroArch Steam final results

The native Steam build launches through App ID 1118310 with Steam Input and the
Steam Overlay. Exposing `/data` through pressure-vessel makes the external
library visible. Current official Libretro buildbot cores can coexist in a
separate managed directory without overwriting Steam DLC cores.

Panda3DS is available as a current Libretro nightly but remains experimental.
Azahar is the preferred standalone 3DS fallback when compatibility or
performance is insufficient.
