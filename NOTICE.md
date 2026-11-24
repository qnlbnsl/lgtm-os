# Notices

## LGTM OS

Copyright (C) 2026 Kunal Bansal and LGTM OS contributors.

LGTM OS's own code (everything in this repository: `integration/`, `packages/`,
`overlay/`, `build.sh`, `tools/`) is free software under the GNU General Public License,
version 3 or (at your option) any later version. See [LICENSE](LICENSE).

## Omarchy

LGTM OS is heavily inspired by Omarchy (https://github.com/omacom/omarchy). The
`diagnose-crash` agent skill (`integration/agents/skills/diagnose-crash/`) is adapted from
Omarchy's, and `lgtm-crash`, `lgtm-agent` and the agent skills follow its design. Material
adapted from Omarchy is used under the MIT License:

```
Copyright (c) David Heinemeier Hansson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## Third-party software

An LGTM OS image is built from Arch Linux packages plus a few others. Each keeps its own
license. The complete, exact list for an image (every package, version, license, project
URL and license file) is generated into the system at `/usr/share/lgtm/NOTICES.md` by
`lgtm-notices`. A pacman hook regenerates it after every package change. On a running
system, see the logo menu: **About & open source licenses**.

Main components:

| Component | Role in LGTM OS | License |
|---|---|---|
| Linux (linux-zen) | Kernel | GPL-2.0-only (with syscall exception) |
| Arch Linux packages | Base system and most programs | Each package's own license |
| systemd | Init, login, networking, zram | LGPL-2.1-or-later and others |
| GRUB, syslinux | Boot loaders | GPL-3.0-or-later, GPL-2.0-or-later |
| archiso | ISO build tooling (build time only) | GPL-3.0-or-later |
| greetd, tuigreet | Login | GPL-3.0-only |
| Wayfire | Glass-mode compositor | MIT |
| labwc | Lite-mode compositor | GPL-2.0-only |
| waybar | Top bar and dock | MIT |
| fuzzel, foot | Launcher, terminal | MIT |
| Wine | Runs Windows apps | LGPL-2.1-or-later |
| Proton (GE-Proton build) | Runs Windows apps and games | BSD-3-Clause; bundled parts (Wine, DXVK, VKD3D-Proton, ...) keep their own licenses |
| umu-launcher | Starts Windows apps with Proton | GPL-3.0-only |
| Waydroid | Runs Android apps | GPL-3.0-or-later |
| distrobox, podman | Run .deb/.rpm apps in containers | GPL-3.0-only, Apache-2.0 |
| Flatpak | Runs Flatpak apps | LGPL-2.1-or-later |
| teams-for-linux | Microsoft Teams client | GPL-3.0-only |
| Darling | Runs Mac apps (preview, off by default) | GPL-3.0-only |
| Papirus icons, Inter font | Look | GPL-3.0, OFL-1.1-RFN |
| WhiteSur icons, apple_cursor | macOS Graphite theme (offline repo, installed on choice) | GPL-3.0-only, GPL-3.0 |
| Plymouth, ReGreet, cage, keyd | Boot splash, login screen, ⌘ key remapping | GPL-2.0-or-later, GPL-3.0-or-later, MIT, MIT |

Installed only when a setup profile is chosen (downloaded on the user's machine, not part
of the image): QEMU (GPL-2.0), libvirt (LGPL-2.1-or-later), quickemu/quickget (MIT), Looking Glass
(GPL-2.0-or-later, built from the AUR), i915-sriov-dkms (GPL-2.0, only if chosen), Lutris (GPL-3.0), Heroic (GPL-3.0), GameMode
(BSD-3-Clause), MangoHud (MIT), Gamescope (BSD-2-Clause), and Steam, which is proprietary
software from Valve distributed by Arch Linux under Valve's own license.

Proprietary firmware and driver blobs in `linux-firmware` are redistributed under their
own licenses (listed per file in `/usr/share/licenses/linux-firmware/`).

## Source code

- LGTM OS: https://github.com/qnlbnsl/lgtm-os
- Arch packages: build recipes at
  `https://gitlab.archlinux.org/archlinux/packaging/packages/<package>`; source archives
  for released versions at https://sources.archlinux.org/
- AUR packages bundled in the image (`aur.txt`) or built by setup profiles:
  https://aur.archlinux.org/packages/<package>
- GE-Proton: https://github.com/GloriousEggroll/proton-ge-custom

## Trademarks

Windows, Microsoft Teams and Microsoft are trademarks of Microsoft Corporation. macOS is a
trademark of Apple Inc. Android is a trademark of Google LLC. Arch Linux is a trademark of
its respective owners. Omarchy is a name of its respective owner. LGTM OS is an independent project, not affiliated with or endorsed
by any of them. It runs apps built for those platforms through open source compatibility
layers.
