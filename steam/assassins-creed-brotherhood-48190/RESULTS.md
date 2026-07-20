# Final conclusions

- Proton Experimental starts the tested Steam build where GE-Proton11-1
  reproducibly faulted during hardware initialization.
- `PROTON_PREFER_SDL=1` enables the game's native Xbox 360 input profile and was
  accepted by the player with the default Steam controller layout unchanged.
- Maximum native quality, 8x MSAA, and `PostFX=0` provide the selected image
  profile without motion blur.
- MangoHud's hidden 60 FPS limiter works; `DXVK_FRAME_RATE=60` did not limit the
  observed title path.
- Ubisoft Connect may remain headless after a clean game exit and keep Steam's
  session running. This is a launcher lifecycle issue, not an ACBSP crash.
