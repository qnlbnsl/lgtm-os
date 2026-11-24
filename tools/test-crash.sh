#!/usr/bin/env bash
# tools/test-crash.sh: crash a program on purpose and check what lgtm-crash does with it.
# Needs a systemd user session with systemd-coredump, plus gdb and the internet (symbols).
# State is kept in a temporary folder; the crash itself stays in `coredumpctl list`.
set -euo pipefail
cd "$(dirname "$0")/.."
T=$(mktemp -d "$HOME/.cache/lgtm-test-XXXXXX"); trap 'rm -rf "$T"' EXIT
mkdir -p "$T"/{bin,state,etc/features}
cp integration/bin/lgtm-crash "$T/bin/"
# Stand-ins: click the notification, pick "Ask AI why", and an agent that stays open.
printf '#!/bin/sh\necho "$*" >> "%s/notified"\necho default\n' "$T" > "$T/bin/notify-send"
printf '#!/bin/sh\necho "Ask AI why"\n' > "$T/bin/fuzzel"
printf '#!/bin/sh\necho "$*" > "%s/agent"\nsleep 20\necho survived > "%s/survived"\n' "$T" "$T" > "$T/bin/lgtm-agent"
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH XDG_STATE_HOME=$T/state LGTM_ETC=$T/etc
R=$T/state/lgtm/crash/reports
# The first scan looks back two minutes: start now, or it finds an earlier run's crashes.
mkdir -p "$T/state/lgtm/crash"; date +%s%6N > "$T/state/lgtm/crash/seen"
fail=0
ok() { if "${@:2}"; then echo "ok    $1"; else echo "FAIL  $1"; fail=1; fi; }
count() { grep -c "lgtm-crashtest crashed" "$T/notified" 2>/dev/null || true; }
wait_for() { local i; for ((i = 0; i < $1 * 2; i++)); do if eval "$2"; then return 0; fi; sleep 0.5; done; return 1; }
cp /usr/bin/sleep "$T/lgtm-crashtest"
crash() {
  "$T/lgtm-crashtest" 60 & pid=$!
  sleep 0.5; kill -SEGV $pid; wait $pid 2>/dev/null || true
  wait_for 20 "coredumpctl list $pid >/dev/null 2>&1"; sleep 1
}

# As the path unit does it: scan inside a oneshot service.
scan() { systemd-run --user --quiet --collect --wait -p Type=oneshot --setenv=PATH="$PATH" \
  --setenv=XDG_STATE_HOME="$XDG_STATE_HOME" --setenv=LGTM_ETC="$LGTM_ETC" "$T/bin/lgtm-crash" scan; }

touch "$T/etc/features/crash-reports"
crash; first=$pid
scan; scan
ok "facts saved"                         wait_for 5 "ls $R/*-$first/crash.json >/dev/null 2>&1"
ok "agent opened with the report"        wait_for 200 "grep -q report.md $T/agent 2>/dev/null"
ok "agent outlives the service"          wait_for 40 "[[ -e $T/survived ]]"
ok "symbols resolved (file and line)"    grep -qE '\.c:[0-9]+' "$R"/*-"$first"/report.md
ok "reports are private"                 test "$(stat -c %a "$R"/*-"$first"/report.md)" = 600
ok "no core left behind"                 test -z "$(find "$HOME/.cache/lgtm" -name core 2>/dev/null)"
ok "one notification for two scans"      test "$(count)" = 1
crash; second=$pid; scan; sleep 2
sed -i '/Collecting/d' "$T/notified"
rm -f "$T/state/lgtm/crash/last-lgtm-crashtest" "$T/etc/features/crash-reports"
lgtm-crash mute lgtm-crashtest >/dev/null; n=$(count)
crash; muted=$pid; scan; sleep 3
ok "muted: facts, no notification"       test "$(count)" = "$n" -a -n "$(ls -d "$R"/*-"$muted")"
ok "feature off: no automatic report"    test -z "$(ls "$R"/*-"$muted"/report.md 2>/dev/null)"
lgtm-crash unmute lgtm-crashtest; rm -f "$T/state/lgtm/crash/last-lgtm-crashtest"
crash; scan
ok "unmuted: notified again"             wait_for 10 "(( \$(count) > $n ))"
ok "feature-off ask still writes report" wait_for 200 "ls $R/*-$pid/report.md >/dev/null 2>&1"
if (( fail )); then sed -n '/^## Backtrace/,/^## Package/p' "$R"/*-"$first"/report.md; fi
echo "pids: $first $second $muted $pid"
exit $fail
