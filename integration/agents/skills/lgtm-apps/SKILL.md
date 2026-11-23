---
name: lgtm-apps
description: >
  REQUIRED for installing, running or fixing apps on LGTM OS, whatever platform they were
  built for: Windows (.exe .msi), Android (.apk), Debian/Ubuntu (.deb), Fedora (.rpm),
  AppImage, Flatpak, Arch packages, macOS (.dmg). Use when an app won't install, won't
  start, crashes, has no menu entry, looks wrong, has no sound, or the user asks how to
  install something. Triggers: install, .exe, .msi, Wine, Proton, GE-Proton, umu, prefix,
  winetricks, .apk, Android, Waydroid, .deb, .rpm, apt, dnf, distrobox, podman, container,
  AppImage, Flatpak, Flathub, Teams, Mac app, Darling, lgtm-open, lgtm-exe.
---

# Apps on LGTM OS

One rule for users: **double-click the file**. `lgtm-open FILE` picks the right method.
Your job is to make that work, and to fix it when it doesn't. Prefer the native route
when one exists: an Arch package (`pacman -Ss name`) beats a container or Wine.

| File | Handler | Where things go |
|---|---|---|
| `.exe .msi .bat .lnk` | `lgtm-exe` (Wine/Proton) | Prefixes `~/.local/share/lgtm/windows/<name>/` |
| `.apk` | `lgtm-android install` (Waydroid) | Android's own storage |
| `.deb` | Ubuntu 24.04 container `lgtm-ubuntu` | Inside the container; apps exported to the menu |
| `.rpm` | Fedora container `lgtm-fedora` | Same |
| `.AppImage` | Copied to `~/Applications`, menu entry added | `~/.local/share/applications/lgtm/appimage-*.desktop` |
| `.flatpak .flatpakref` | `flatpak --user` (Flathub) | `~/.local/share/flatpak` |
| `.pkg.tar.zst` | `sudo pacman -U` | System |
| `.dmg .app` | `lgtm-mac` (Darling, preview) | — |

**Logs first.** Every install/run writes `~/.cache/lgtm/logs/<name>.log`. Read it before
guessing.

## Windows apps (`lgtm-exe`)
- `lgtm-exe [--prefix NAME] [--runner proton|wine] FILE [ARGS]`.
- Default runner `proton`: umu-launcher + GE-Proton. Set `RUNNER=wine` in
  `~/.config/lgtm/windows.conf` for faster start or offline use.
- Proton version: weekly-updated copy in `~/.local/share/lgtm/proton/current`, else the
  bundled `/usr/share/lgtm/proton`. Check with `lgtm-proton-update --status`; update now
  with `lgtm-proton-update`.
- All apps share one prefix per runner (`proton`, `wine`). A prefix remembers its runner in
  `.lgtm-runner`; don't mix. For an app that breaks others, install it in its own prefix:
  `lgtm-exe --prefix appname setup.exe`.
- Menu entries come from the prefix's Start Menu `.lnk` files via `lgtm-menu-sync`
  (runs after every launch). Missing entry → run `lgtm-menu-sync --prefix <path>` and check
  the installer actually created a Start Menu shortcut.
- Debug output is off (`WINEDEBUG=-all`). To debug: `WINEDEBUG=err+all lgtm-exe FILE`.
- Missing runtime (VC++ redist, .NET, fonts): winetricks into the prefix:
  `WINEPREFIX=~/.local/share/lgtm/windows/wine winetricks vcrun2022` for the wine prefix.
  For a Proton prefix use `umu-run winetricks ...` with the same `WINEPREFIX`, `GAMEID=umu-default`
  and `PROTONPATH` that lgtm-exe uses.
- Teams: use `teams-for-linux` (native). The Windows Teams app doesn't work under Wine.

## Android (`lgtm-android`)
- Nothing runs until first use. First use downloads Android (~1 GB, needs ~2 GB RAM).
- `lgtm-android` (full screen), `launch PKG`, `install FILE.apk`, `stop` (frees RAM).
- Status: `waydroid status`. Logs: `waydroid log`, `journalctl -u waydroid-container`.

## .deb / .rpm (rootless containers)
- Containers: `distrobox list`. Enter one: `distrobox enter lgtm-ubuntu`.
- Manage packages inside: `distrobox enter lgtm-ubuntu -- sudo apt install|remove PKG`.
- Re-add a menu entry: `distrobox enter lgtm-ubuntu -- distrobox-export --app NAME --export-label none`.
- Remove one: same with `--delete`, then remove the package with apt.
- Containers cost no RAM until an app runs (podman has no daemon). Updates run weekly via
  `lgtm-apps-update` (user timer `lgtm-apps-update.timer`).
- `podman` errors about subuid/subgid: the user needs ranges in `/etc/subuid` and
  `/etc/subgid` (`sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 USER`).

## Snaps
Not supported (snapd needs a system daemon). Look for the same app on Flathub or as a .deb.
