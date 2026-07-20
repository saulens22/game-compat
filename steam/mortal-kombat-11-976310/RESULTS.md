# Mortal Kombat 11 final results

- Final status: launches, but remains unplayable at approximately 7–14 FPS in animated menus and gameplay; no tested route sustained more than roughly 15 FPS.
- DX11 and DX12 both reproduced the problem.
- GE-Proton 9-11, GE-Proton 10-34, Proton-GE Latest 11-1, and Proton Experimental did not fix it.
- Minimum graphics, fullscreen/borderless, HDMI/internal displays, Steam Overlay on/off, and stable/beta Steam paths did not fix it.
- Wine synchronization overrides, VKD3D immediate presentation, NVAPI disabling, large-address-aware disabling, write-watch investigation, and `noforcelgadd` did not fix it.
- GPU utilization remained low during affected runs, so the recorded evidence does not point to ordinary GPU saturation.
- Steam launch routing can resolve to `MK11.exe` when a test intends to exercise `MK11_DX12.exe`; the live process must be verified when comparing future updates.
- Keep `FrameSkip = 1`: temporarily setting it to `0` did not improve performance and disables online play.
- A static transition briefly reached about 60 FPS, but animated content immediately returned to the low cadence and this was not a fix.
