---
name: lgtm
description: >
  REQUIRED for changing or troubleshooting the LGTM OS desktop and system. Use when the
  user wants to change how their desktop looks or behaves (dock, top bar, wallpaper,
  blur/glass, keybindings, window buttons, fonts, theme, glass vs lite mode), wants to set
  the machine up for gaming / a Windows VM / development, asks why
  the system is slow or using memory, wants to change login/autologin, networking or
  Wi-Fi, or asks how LGTM OS works. Triggers: waybar, dock, top bar, wayfire, labwc,
  glass mode, lite mode, blur, keybinding, shortcut, wallpaper, theme, graphite, fuzzel,
  foot, greetd, login, RAM, memory, slow, zram, gaming, steam, setup profile, VM, virtual
  machine, Windows VM, Looking Glass, GPU passthrough, SR-IOV, libvirt, container, distrobox,
  lgtm-pod, lgtm-session, lgtm-mem, lgtm-setup, lgtm-vm.
---

# LGTM OS

LGTM OS is a lightweight Arch Linux desktop. Its promise: **the system plus desktop fits
in 128 MB of RAM**, and nothing heavy runs until the user opens it. Every change you make
must keep that promise. If a change adds something that runs all the time, say what it
costs in RAM and ask first.

## Safety rules
- Never edit files under `/usr/share/lgtm/`, `/usr/lib/`, or `/usr/bin/`. They belong to
  packages and are replaced on update. Make user-level overrides instead (below).
- Read a config before editing it. Back it up first: `cp file file.bak.$(date +%s)`.
- System changes (anything under `/etc`, packages, services) need `sudo`. Say what you will
  run and why before running it.
- Don't add background services, timers or polling widgets without asking.

## How the desktop starts
`greetd` (login) → `lgtm-session` → one of two compositors:

| Mode | Compositor | Look | Chosen when |
|---|---|---|---|
| glass | Wayfire | Real blur, wallpaper | GPU present and RAM ≥ 1.5 GB |
| lite  | labwc   | Same layout, translucent without blur | Small machines, VMs, no GPU |

Force a mode in `~/.config/lgtm/session.conf`: `MODE=glass`, `MODE=lite` or `MODE=auto`.
Takes effect at next login. The logo menu (top-left) can switch it too.

Both modes run one `waybar` process with two bars: the Mac-style top bar and the dock.

## Where config lives (and how to override it)
Defaults are in `/usr/share/lgtm/`. Users override by copying to `~/.config`:

| What | Default | User override |
|---|---|---|
| Glass mode (Wayfire): keys, blur, animations | `/usr/share/lgtm/wayfire.ini` | `~/.config/wayfire.ini` (whole file; lgtm-session prefers it) |
| Lite mode (labwc): keys, theme, menu | `/usr/share/lgtm/labwc/` | `~/.config/labwc/` (copy the whole dir; needs `rc.xml`) |
| Top bar + dock layout | `/usr/share/lgtm/waybar/config.jsonc.in` | See below |
| Top bar + dock style | `/usr/share/lgtm/waybar/style.css`, `lite.css` | See below |
| Launcher, terminal, GTK, default apps | `/usr/share/lgtm/xdg/{fuzzel,foot,gtk-3.0,mimeapps.list}` | Same path under `~/.config/` (standard XDG lookup) |

waybar's config is generated at each login into `$XDG_RUNTIME_DIR/lgtm/` from the
`.in` template (dock icon paths are filled in). To customise the bar or dock, copy the
template and CSS to `~/.config/lgtm/waybar/`, edit them, and change the `waybar` line in
the user's compositor override to point there. Placeholders like `@ICON_WEB@` must be
replaced with real icon paths in a user copy.

After editing: Wayfire reloads `wayfire.ini` automatically. labwc: `labwc --reconfigure`.
waybar: `pkill -SIGUSR2 waybar` reloads style, or `pkill waybar` and start it again.

## Keyboard style and keybindings
Chosen in the installer; check with `lgtm-keys`, switch with `sudo lgtm-keys mac|windows`
(or the logo menu), then log out and in. A user can override per account with
`KEYS=mac|windows` in `~/.config/lgtm/session.conf`, but the ⌘C/⌘V remapping (keyd,
`/etc/keyd/lgtm-mac.conf`) is system-wide.

Bindings live in `/usr/share/lgtm/keys/<style>/{wayfire.ini,labwc.xml}`. lgtm-session merges
them with the base configs into `$XDG_RUNTIME_DIR/lgtm/` at login. To customise, copy the
generated `$XDG_RUNTIME_DIR/lgtm/wayfire.ini` to `~/.config/wayfire.ini` (or the generated
`labwc/` dir to `~/.config/labwc/`) and edit that.

| Action | macOS style | Windows style |
|---|---|---|
| Launcher / search | ⌘Space | Tap Super, Win+S |
| Copy / paste / cut / undo | ⌘C ⌘V ⌘X ⌘Z (keyd) | Ctrl+C/V/X/Z |
| Close window | ⌘Q | Alt+F4 |
| Switch windows | ⌘Tab | Alt+Tab |
| Overview | Ctrl+↑ | Win+Tab |
| Terminal | ⌘Return | Ctrl+Alt+T, Win+Return |
| Files | ⌘⌥Space | Win+E |
| AI agent | ⌘⇧A | Win+A |
| Lock | Ctrl+⌘Q | Win+L |
| Screenshot (full / area) | ⌘⇧3 / ⌘⇧4 | PrtSc / Win+Shift+S |
| Minimise / fullscreen | ⌘M, ⌘H / Ctrl+⌘F | Win+↓ / F11 |
| Snap / maximise | Ctrl+⌘Return (max) | Win+←/→, Win+↑ |
| Show desktop | — | Win+D (glass mode) |
| Desktops | Ctrl+⌘←/→ | Ctrl+Win+←/→ |
| Power menu | ⌘⌥Esc | Ctrl+Alt+Del |

## Themes
`lgtm-theme` lists them, `lgtm-theme NAME` switches live (logo menu: Theme…). Shipped:
`aurora` (default blue glass) and `macos-graphite`. A theme is a folder in
`/usr/share/lgtm/themes/<name>/`: `theme.conf` (colours, icon + cursor theme, terminal
palette), `wallpaper.png`, and optionally `packages` (what it needs, installed by
`lgtm-pkg` on switch). The user's choice is `THEME=` in `~/.config/lgtm/session.conf`;
the system default (login screen, new users) is `/etc/lgtm/theme` (`sudo lgtm-theme --default NAME`).

Custom theme: copy `/usr/share/lgtm/themes/aurora` to `~/.config/lgtm/themes/<new-name>/`,
edit `theme.conf` (set LABEL; put any wallpaper.png in the folder), then
`lgtm-theme <new-name>`. User themes appear in the menu next to the built-in ones.
lgtm-session generates every app's colours from theme.conf (`$XDG_RUNTIME_DIR/lgtm/`);
`lgtm-session --apply` reloads them live.

## Setup profiles (gaming, VMs, dev)
`lgtm-setup` lists them, `lgtm-setup NAME` installs one (logo menu: Set up…). Each is
`/usr/share/lgtm/profiles/<name>/`: `packages` (pacman names; `aur:BASE [pkgs]` lines are
built from the AUR by `lgtm-pkg`) + an optional root `setup` script. Done markers:
`/var/lib/lgtm/profiles/`. The installer queues choices in `/etc/lgtm/setup-pending`;
they run in a terminal at first login.
- **gaming**: Steam, Heroic, Lutris, GameMode, MangoHud, Gamescope + Vulkan driver per GPU.
  Steam finds the bundled GE-Proton in `/usr/share/steam/compatibilitytools.d`.
- **dev**: git, gh, node, uv, go, rustup, ripgrep, fd, fzf, podman-docker, ...
- **vm**: QEMU/libvirt, quickget, Looking Glass B8 (rc, AUR), kvmfr module, IOMMU options,
  the `lgtm-tuning` libvirt hook.

## Virtual machines (lgtm-vm)
`lgtm-vm` opens the user's VM (or a picker, or the wizard if there are none). `lgtm-vm new`
asks for an OS (downloaded with quickget: Windows 11 straight from Microsoft, ~100 Linux/BSD;
or a link, or a local file) and sizes the VM. Each VM gets a menu entry.
`lgtm-vm gpus` explains what graphics this PC can give a VM. The wizard tries, in order:
1. **Spare GPU passthrough**: a second desktop GPU, or a laptop's render-only NVIDIA/AMD
   GPU (class "3D controller", no ports) while the Intel GPU keeps the desktop. Windows is
   shown through **Looking Glass B8**, whose virtual display driver (IDD) replaces dummy
   plugs. B8 is a release candidate: client and Windows host must both be B8.
   Laptop NVIDIA quirks added automatically: fake battery ACPI table
   (`/var/lib/lgtm/vm/battery.aml`), the laptop's PCI subsystem IDs, vBIOS if readable.
   Code 43 in Windows = needs the vBIOS file (see `lgtm-vm gpus`).
   The GPU is listed in `/etc/lgtm/vm-gpus`; lgtm-session hides it from the compositor
   (WLR_DRM_DEVICES) so it can be detached. "GPU still in use by ..." = log out and in.
2. **Intel GPU slice (SR-IOV)**: `lgtm-vm share-gpu on` (i915-sriov-dkms, experimental,
   can break on kernel updates; `/etc/lgtm/sriov`, `lgtm-sriov.service`).
3. **Linux guests: 3D virtual GPU** (virtio-gpu + VirGL on the host's render node).
4. **Plain virtual display**. No 3D; Windows on a single GPU without SR-IOV ends here
   (there is no paravirtual DirectX for Windows guests). Suggest Proton for games.
- Definitions: `~/.config/lgtm/vm/<name>.xml` + `.json` (keep: UUID, MAC, pinned machine
  type = Windows activation). `lgtm-vm edit/stop/delete/list`. virsh/virt-manager also work.
- Passthrough VMs get hugepages + pinned cores; `/etc/libvirt/hooks/qemu.d/lgtm-tuning`
  keeps host processes/IRQs off those cores while running. "only N/M hugepages free" =
  close apps or give the VM less memory.
- Looking Glass config: `/usr/share/lgtm/looking-glass/client.ini` (user override in
  `~/.config/looking-glass/client.ini`); frame buffer size `/etc/modprobe.d/kvmfr.conf`.
  Right Ctrl captures input. One Looking Glass VM at a time.

## Containers (lgtm-pod)
Other distros via distrobox + rootless podman. `lgtm-pod new` (ubuntu, debian, fedora,
arch, alpine, opensuse, kali, any image), `lgtm-pod install NAME PKG...` (distro's own
package manager; new apps are exported to the menu), `enter`, `run`, `export NAME APP
[--bin]`, `list`, `rm`, `upgrade`. Pods share home (optional separate home in
`~/.local/share/lgtm/pods/`), display, sound, GPU. `.deb`/`.rpm` files use the
`lgtm-ubuntu` / `lgtm-fedora` pods via lgtm-open. distrobox/podman commands work too.

## Login and boot
- Encrypted installs: the password typed at the boot splash (Plymouth theme `lgtm`) unlocks
  the disk; greetd then logs in automatically. `/etc/greetd/config.toml` `[initial_session]`.
- Otherwise the graphical login is ReGreet in cage (`/usr/share/lgtm/regreet/`).
- Kernel options are in `/etc/default/grub` (`grub-mkconfig -o /boot/grub/grub.cfg` after
  editing). Initramfs hooks: `/etc/mkinitcpio.conf.d/lgtm.conf` (`mkinitcpio -P` after editing).

## Commands
Every LGTM OS command is `lgtm-*`; list them with `compgen -c lgtm- | sort -u`. Each one
prints usage with `--help` or no arguments.

| Command | Purpose |
|---|---|
| `lgtm-session` | Starts the desktop (picks the mode) |
| `lgtm-mem` | RAM used by the system + biggest processes. Target ≤ 128 MB at idle |
| `lgtm-power` | Logo menu: agent, theme, setup, keyboard style, mode, power |
| `lgtm-open FILE` | Install/run any app package (see the `lgtm-apps` skill) |
| `lgtm-agent` | Launch the default AI agent (`--pick` to choose, `--prompt TEXT`) |
| `lgtm-keys` | Show or set the keyboard style (mac / windows) |
| `lgtm-screenshot full\|region` | Screenshot to ~/Pictures/Screenshots + clipboard |
| `lgtm-lock` | Lock the screen |
| `lgtm-theme [NAME]` | List or switch themes |
| `lgtm-setup [NAME]` | List or install setup profiles (gaming, windows-vm, dev) |
| `lgtm-pkg FILE` | Install a packages list (repo + AUR) |
| `lgtm-vm [new\|open\|stop\|list\|gpus\|share-gpu]` | Virtual machines (wizard) |
| `lgtm-pod [new\|enter\|install\|rm]` | Containers for other distros |
| `lgtm-install` | Installer (live ISO only) |

## Memory and speed
- Check with `lgtm-mem`. Compare against the 128 MB target, ignoring apps the user opened.
- Memory tools in place: zram swap (`/usr/lib/systemd/zram-generator.conf`), earlyoom
  (kills runaway apps, never the desktop), volatile journal capped at 8 MB.
- Audio (PipeWire), notifications (mako), portals start on first use: that's expected.
- Network is `iwd` (Wi-Fi, `impala` TUI) + `systemd-networkd` (wired). No NetworkManager.
- If RAM is tight in glass mode, suggest lite mode before anything else.

