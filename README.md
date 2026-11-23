# LGTM OS

A lightweight Arch-based desktop that runs Windows, Linux, Android and (in preview) Mac apps.
The system and desktop fit in **128 MB of RAM**. Apps use more while they run, and nothing
heavy runs until you use it.

## Goals
1. **Fast and light.** The base system plus desktop must stay at or under 128 MB.
2. **Just works.** Double-click a `.exe`, `.msi` or `.apk` and it installs and shows up in the menu.
3. **Fully open source.** Everything comes from official Arch repos, apart from two
   prebuilt AUR packages (Teams, Darling) and our own glue.

## How it stays small
| Piece | Choice | Why |
|---|---|---|
| Kernel | linux-zen | Responsive, and includes binder for Android |
| Login | greetd + tuigreet | A few MB, versus 50+ MB for SDDM/GDM |
| Desktop | `lgtm-session` picks **Glass** or **Lite** | Blur only where the hardware can afford it |
| Network | iwd + systemd-networkd | About 20 MB less than NetworkManager |
| Memory | zram (zstd), earlyoom, volatile journal | 128 MB behaves like about 300 MB |
| Audio, notifications, portals | Socket- or D-Bus-activated | 0 MB until first use |
| Wine/Proton, Waydroid | Start on demand | 0 MB until you open an app |

### Two modes, one look
Both modes have a Mac-style top bar and a floating frosted dock, with window buttons on the left.
- **Glass:** Wayfire with Kawase blur and a wallpaper. Chosen automatically with a real GPU and at least 1.5 GB RAM.
- **Lite:** labwc, translucent panels without blur, and a single-pixel (about 0 MB) background. Used on small machines and VMs.

Force a mode in `~/.config/lgtm/session.conf` with `MODE=glass` or `MODE=lite`, or use the
logo menu (top-left).

## Running apps
| Type | How | Notes |
|---|---|---|
| Windows `.exe/.msi/.bat/.lnk` | `lgtm-exe` (double-click, or `./setup.exe` via binfmt) | umu-launcher with bundled GE-Proton; falls back to plain Wine when offline. Start Menu shortcuts become app menu entries automatically (`lgtm-menu-sync`). |
| Teams | `teams-for-linux` | An open-source native Wayland client. The Windows Teams app doesn't run properly under Wine. |
| Android `.apk` | `lgtm-android install` (double-click) | Waydroid. Downloads Android (about 1 GB) once on first use. Needs about 2 GB RAM. "Stop Android" in the logo menu frees it. |
| Mac | `lgtm-mac enable`, then `lgtm-mac run` | **Preview.** Darling runs command-line Mac programs; graphical apps mostly don't work. |

Windows settings live in `~/.config/lgtm/windows.conf`: `RUNNER=proton` (best compatibility) or
`RUNNER=wine` (faster start, offline). Prefixes are in `~/.local/share/lgtm/windows/`.

## Build
```sh
sudo pacman -S --needed archiso base-devel git curl qemu-desktop edk2-ovmf
./build.sh                # -> out/lgtm-os-YYYY.MM.DD-x86_64.iso
tools/vm.sh live 2048     # try the live ISO
tools/vm.sh install 2048  # install to a VM disk (lgtm-install)
tools/vm.sh disk 128      # boot the installed system with 128 MB; run lgtm-mem
```
`build.sh` builds the AUR packages listed in `aur.txt`. Read their PKGBUILDs (in
`cache/aur/`) before building.

## Layout
- `integration/`: our code (launchers, session, look, tuning), packaged as `lgtm-integration`
- `packages/`: PKGBUILDs (`lgtm-integration`, `lgtm-ge-proton`)
- `overlay/airootfs/`: live-ISO-only files
- `packages.x86_64`: what goes on the ISO
- `build.sh`: archiso build (based on archiso's `releng` boot setup)
- `tools/vm.sh`: QEMU test runner

## Licenses
LGTM OS's own code is GPL-3.0-or-later. Bundled components keep their own licenses
(Wine LGPL-2.1+, Proton BSD-3-Clause plus bundled parts, umu GPL-3.0, Waydroid GPL-3.0,
Darling GPL-3.0, labwc GPL-2.0, Wayfire MIT, waybar MIT, Linux GPL-2.0, and so on).
