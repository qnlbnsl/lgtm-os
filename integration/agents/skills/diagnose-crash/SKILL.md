---
name: diagnose-crash
description: >
  Diagnose why a program crashed on LGTM OS from its systemd-coredump core dump. Use when
  a process segfaulted, aborted or dumped core, when the user asks why an app crashed or
  disappeared, or when an "App crashed" notification was clicked (lgtm-crash hands the
  facts over). Triggers: crash, segfault, SIGSEGV, SIGABRT, core dump, coredumpctl,
  backtrace, "why did X crash", "X keeps crashing".
---

# Diagnose a crash

Goal: a short, honest answer to "why did it crash, and what can I do?", backed by evidence.
Don't guess, and don't change the system unless the user agrees to a fix.

## 1. Establish the facts
```sh
coredumpctl list --since=-1d            # find it: time, PID, signal, executable
coredumpctl info PID                    # signal, command line, cgroup, stack summary
```
Note the executable, the signal, the time, and whether it has happened before
(`coredumpctl list EXE`). A one-off is different from a pattern.

## 2. Rule out the boring causes first
- **Out of memory:** `journalctl -b --since=-15min | grep -iE 'earlyoom|oom|killed process'`.
  earlyoom kills runaway apps on purpose (SIGTERM/SIGKILL, often no core dump). On LGTM OS
  this is the most common "crash". Suggest lite mode or closing apps; check `lgtm-mem`.
- **Just updated:** `grep -E 'upgraded|installed' /var/log/pacman.log | tail -20`. A crash
  right after an update of the program or its libraries points to a packaging bug.
- **Windows app:** if the executable is `wine*`, `wineserver`, a `.exe` or under
  `~/.local/share/lgtm/windows/`, read `~/.cache/lgtm/logs/<app>.log` and use the
  `lgtm-apps` skill instead.
- **Container app (.deb/.rpm):** crashes inside `lgtm-ubuntu`/`lgtm-fedora` must be debugged
  inside the container.

## 3. Read the backtrace
```sh
coredumpctl debug PID -A '-batch -ex "thread apply all bt"'   # needs gdb
```
If gdb is missing, say so and ask before installing it (`sudo pacman -S gdb`).
Symbols: Arch serves them on demand via debuginfod; `export DEBUGINFOD_URLS=https://debuginfod.archlinux.org`
before running gdb. Read the top frames of the crashing thread: which library, which
function. Frames only in a GPU driver (mesa, nvidia) point at graphics; in libc `abort`
look for the assertion message in `coredumpctl info`.

## 4. Report
Tell the user, briefly:
1. What crashed and when (one line).
2. The most likely cause and the evidence (OOM log line, frame, assertion).
3. What they can do now (restart it, lite mode, roll back a package with
   `sudo pacman -U /var/cache/pacman/pkg/NAME-OLDVER...`, update).
4. Whether it's a bug worth reporting upstream, and where. Offer to draft the report with the
   backtrace; never file it without their OK.

Label anything you couldn't verify as a guess.
