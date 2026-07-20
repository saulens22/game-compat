# Tested environment

Public hardware and package snapshot captured on 2026-07-20. It describes the
machine used for these cases without publishing account names, serial numbers,
home paths, or display-specific assumptions. Individual game pages list the
compatibility builds and variants actually exercised for that game.

## Hardware

| Component | Tested value |
| --- | --- |
| CPU | AMD Ryzen 7 7840HS, 8 cores / 16 threads |
| Memory | 62 GiB usable system memory |
| Discrete GPU | NVIDIA GeForce RTX 4060 Laptop GPU, 8 GiB VRAM |
| Integrated GPU | AMD Radeon 780M Graphics |
| Architecture | x86_64 |

## Operating system and desktop

| Component | Tested value |
| --- | --- |
| Distribution | CachyOS |
| Kernel | `linux-cachyos 7.1.4-1` |
| Desktop | KDE Plasma on Wayland |
| Steam package | `steam 1.0.0.86-2` |
| Observed Steam client build | `1784145295` |

Display resolution and connector are intentionally not part of the shared
baseline. A game page only mentions a display when it was an explicit variable
in that game's experiment.

## Graphics and compatibility packages

| Package or runtime | Tested version |
| --- | --- |
| NVIDIA kernel package | `linux-cachyos-nvidia-open 7.1.4-1` |
| NVIDIA userspace | `nvidia-utils 610.43.03-1` |
| NVIDIA 32-bit userspace | `lib32-nvidia-utils 610.43.03-1` |
| NVIDIA Vulkan driver | `610.43.03` |
| Mesa | `3:26.1.5-1` |
| Mesa 32-bit | `3:26.1.5-1` |
| AMD Vulkan driver | RADV, Mesa `26.1.5-arch3.1` |
| Vulkan loader/tools | `1.4.350.1` |
| Wine | `11.13-1.1` |
| mpv | `0.41.0-3.1` |
| MangoHud | `0.8.4-1.1` |
| MangoHud 32-bit | `0.8.4-1` |

## Installed Proton builds relevant to the cases

| Compatibility tool | Reported build |
| --- | --- |
| Proton-GE Latest | `GE-Proton11-1` |
| GE-Proton 10-34 | `GE-Proton10-34` |
| GE-Proton 9-11 installation | Reports `GE-Proton9-10-18-g3763cd3a` internally |
| Proton Experimental | Steam-managed; exact deployed build can change |

Package versions are evidence for this snapshot, not universal requirements.
Use each game's `requirements.txt` and setup command instead of copying this
package list to another distribution.
