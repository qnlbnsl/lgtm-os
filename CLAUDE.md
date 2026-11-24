# LGTM OS

Arch-based desktop that runs Windows, Linux, Android and (preview) Mac apps. What it does
and why each part was chosen: [README.md](README.md). Latest state and untested list: the
newest file in `docs/sessions/`.

## Rules
- **128 MB budget.** Base system plus desktop must idle at or under 128 MB (check with
  `lgtm-mem` in a VM). No new always-running process: use socket, D-Bus, path or timer
  activation. Prefer a script over a daemon.
- **Just works.** A non-technical user must never need the terminal. Errors need a plain
  message (`die` in the scripts, or a notification when there's no terminal).
- **Open source.** Official Arch repos first. AUR packages built into the ISO must be
  `-bin` or plain assets (`aur.txt`); anything that compiles goes in a profile's
  `packages` file as `aur:NAME` and builds on the user's machine.
- New bundled software gets a line in `NOTICE.md`.
- Both modes must work: Glass (Wayfire) and Lite (labwc); so must both keyboard styles
  (mac, windows) and every theme.

## Where things go
- `integration/` is packaged as `lgtm-integration`. A new folder or `.desktop` file there
  also needs a line in `packages/lgtm-integration/PKGBUILD`. New `bin/` scripts are
  picked up automatically.
- `overlay/airootfs/` is copied to the ISO, and `lgtm-install` copies the ISO to disk, so
  live-only files must also be removed in `lgtm-install`'s chroot step.
- User-visible behaviour changes also update `integration/agents/skills/` (what AI agents
  on an installed system read).

## Commands
- `tools/check.sh`: run before every commit (no root needed). CI runs it too.
- `tools/check.sh packages`: run after changing any package list.
- `./build.sh`: full ISO. Needs archiso; asks for sudo; runs AUR PKGBUILDs on this
  machine, so read them first (`cache/aur/`).
- `tools/vm.sh live|install|disk [MB]`: boot it in QEMU (`UEFI=1` for OVMF).

The checks prove nothing about booting: say "not booted" unless a VM run was done.
