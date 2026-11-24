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

## Install
`lgtm-install` (on the live desktop: **Install LGTM OS**) asks for a disk, your name and
password, time zone, and two choices:
- **Keyboard style:** macOS (Super is ⌘; ⌘C/⌘V/⌘Q/⌘Space…, window buttons on the left) or
  Windows (tap Super for apps, Win+E/L/D, Win+arrows snap, buttons on the right).
  Switch later from the logo menu or with `sudo lgtm-keys mac|windows`.
- **Disk encryption** (recommended): like Omarchy, the password typed at the boot splash
  is the only one, and the desktop opens by itself. Without encryption you choose
  between automatic login and a graphical login screen (ReGreet), which exits after login.

- **Theme:** Aurora (blue glass) or macOS Graphite (neutral grays, WhiteSur icons, macOS
  cursor). Switch any time: logo menu → Theme…, or `lgtm-theme macos-graphite`.
- **What it's for** (any of): Gaming, Windows VM, Developer & AI agents. These install on
  first login, when there's internet; add more later with `lgtm-setup`.

Boot is quiet: GRUB hidden, Plymouth splash with the LGTM logo.

## One OS, set up for what you do
| Profile | What you get |
|---|---|
| `gaming` | Steam, Heroic (Epic/GOG), Lutris, GameMode, MangoHud, Gamescope, Vulkan drivers for your GPU. Games use the bundled GE-Proton. |
| `vm` | Virtual machines with `lgtm-vm`: pick Windows 11, Ubuntu, Fedora, ... (or paste an ISO link) and it's downloaded and sized for your PC. With a spare GPU, including a laptop's NVIDIA/AMD GPU, Windows runs at full speed through Looking Glass, no dummy plug. |
| `dev` | git, GitHub CLI, Node, uv, Go, Rust, ripgrep/fd/fzf, Docker-compatible podman. AI agents install from the dock on first use. |

Virtual machines pick the best graphics this PC allows, in order: pass through a spare
GPU, a slice of the Intel GPU (SR-IOV, experimental), a 3D virtual GPU (Linux guests),
then a plain virtual display. `lgtm-vm gpus` explains the choice. Containers for other
distros: `lgtm-pod new`, then `lgtm-pod install <pod> <package>` puts the app in the menu.
The underlying tools (virsh, virt-manager, distrobox, podman) still work on everything.

Profiles and themes are plain folders (`/usr/share/lgtm/profiles`, `/usr/share/lgtm/themes`)
with a `packages` list; AUR entries are built on the machine when needed.

## Running apps
Double-click any app package and `lgtm-open` handles it:

| Package | Built for | How LGTM OS runs it |
|---|---|---|
| `.exe` `.msi` `.bat` `.lnk` | Windows | Wine/Proton (below) |
| `.apk` | Android | Waydroid (below) |
| `.deb` | Debian/Ubuntu | Rootless Ubuntu 24.04 container (distrobox + podman); apps exported to the menu, CLIs to `~/.local/bin` |
| `.rpm` | Fedora/RHEL/SUSE | Rootless Fedora container, same way |
| `.AppImage` | Any Linux | Kept in `~/Applications`, added to the menu with its icon |
| `.flatpak` `.flatpakref` | Flatpak | `flatpak --user` with Flathub |
| `.pkg.tar.zst` | Arch | pacman |
| `.dmg` `.app` | macOS | Darling (preview) |

Containers use podman with no background service, so they cost no RAM until an app runs.
Apps installed from `.deb`, `.rpm` and Flatpak update weekly (`lgtm-apps-update`).
`.snap` isn't supported (snapd needs a system daemon); most snaps are also on Flathub.

### Details per platform
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
`tools/check.sh` runs the fast checks (no root, no build); `tools/check.sh packages` checks that
every listed package still exists. CI runs both.

`build.sh` builds the AUR packages listed in `aur.txt`. Read their PKGBUILDs (in
`cache/aur/`) before building.

## Layout
- `integration/`: our code (launchers, session, look, tuning), packaged as `lgtm-integration`
- `packages/`: PKGBUILDs (`lgtm-integration`, `lgtm-ge-proton`)
- `overlay/airootfs/`: live-ISO-only files
- `packages.x86_64`: what goes on the ISO
- `build.sh`: archiso build (based on archiso's `releng` boot setup)
- `tools/vm.sh`: QEMU test runner
- `tools/check.sh`: fast checks, also run by CI

## Licenses
LGTM OS's own code is GPL-3.0-or-later ([LICENSE](LICENSE)). Bundled components keep their
own licenses: see [NOTICE.md](NOTICE.md). Every image also carries a complete, generated list
of all installed packages and licenses at `/usr/share/lgtm/NOTICES.md` (logo menu → About &
open source licenses).
