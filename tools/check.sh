#!/usr/bin/env bash
# tools/check.sh: fast checks that need no root, no build and no VM.
#
#   tools/check.sh           scripts, XML, desktop entries
#   tools/check.sh packages  every listed package exists (needs an Arch system with a
#                            fresh `pacman -Sy`, plus internet for the AUR)
#
# Linters (shellcheck, ruff) are used from PATH, or fetched through uvx.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
bad() { echo "FAIL: $*" >&2; fail=1; }
tool() {  # tool NAME PYPI-PACKAGE -> sets RUN
  if command -v "$1" >/dev/null; then RUN=("$1")
  elif command -v uvx >/dev/null; then RUN=(uvx --from "$2" "$1")
  else echo "missing $1 (install $1, or uv)" >&2; exit 2; fi
}
# Tracked and new files, so work in progress is checked too. Files deleted but
# not yet staged are skipped.
files() { git ls-files -co --exclude-standard "$@" | while read -r f; do if [[ -f $f ]]; then echo "$f"; fi; done; }
scripts() {  # scripts SHEBANG-REGEX
  files | while read -r f; do if head -n1 "$f" | grep -aqE "$1"; then echo "$f"; fi; done
}

check_scripts() {
  local sh py f
  mapfile -t sh < <(scripts '^#!.*[/ ](ba)?sh$')
  (( ${#sh[@]} )) || bad "found no shell scripts to check"
  tool shellcheck shellcheck-py
  # SC1090: theme.conf/profile.conf paths are only known at run time.
  # SC2054: QEMU options really do contain commas.
  "${RUN[@]}" -S warning -e SC1090,SC2054 "${sh[@]}" || bad shellcheck

  mapfile -t py < <(scripts '^#!.*python3?$')
  (( ${#py[@]} )) || bad "found no Python scripts to check"
  tool ruff ruff
  for f in "${py[@]}" ; do
    "${RUN[@]}" check -q --isolated --no-cache --select E9,F,B --stdin-filename "$f.py" - < "$f" || bad "ruff: $f"
  done

  for f in integration/bin/*; do [[ -x $f ]] || bad "not executable: $f"; done
}

check_data() {
  local f
  if command -v xmllint >/dev/null; then
    while read -r f; do
      # keys/*/labwc.xml are fragments that lgtm-session merges into rc.xml.
      if [[ $f == */keys/* ]]; then
        { echo '<x>'; cat "$f"; echo '</x>'; } | xmllint --noout - || bad "xml: $f"
      else
        xmllint --noout "$f" || bad "xml: $f"
      fi
    done < <(files '*.xml')
  else echo "skipped: xml (no xmllint)"; fi
  if command -v desktop-file-validate >/dev/null; then
    while read -r f; do desktop-file-validate --no-hints "$f" || bad "desktop: $f"; done < <(files '*.desktop')
  else echo "skipped: desktop entries (no desktop-file-validate)"; fi
}

check_packages() {
  command -v pacman >/dev/null || { echo "needs pacman" >&2; exit 2; }
  local lists=(packages.x86_64 integration/share/lgtm/{profiles,themes}/*/packages)
  local aur p known
  aur=$({ awk '!/^#/ && NF {print $1}' aur.txt; sed -nE 's/^aur:(\S+).*/\1/p' "${lists[@]}"; } | sort -u)
  # Ours, or built from the AUR into the local repo.
  known=" lgtm-integration lgtm-ge-proton $(tr '\n' ' ' <<< "$aur")"
  while read -r p; do
    [[ $known == *" $p "* ]] && continue
    pacman -Si "$p" >/dev/null 2>&1 || pacman -Sg "$p" >/dev/null 2>&1 || bad "not in the Arch repos: $p"
  done < <(sed -E 's/#.*//' "${lists[@]}" | awk 'NF && $1 !~ /^aur:/ {print $1}' | sort -u)
  for p in $aur; do
    local reply
    reply=$(curl -fsSL --retry 3 "https://aur.archlinux.org/rpc/v5/info?arg[]=$p") || { bad "AUR lookup failed: $p"; continue; }
    grep -q '"resultcount":1' <<< "$reply" || bad "not in the AUR: $p"
  done
}

case ${1:-scripts} in
  scripts)  check_scripts; check_data ;;
  packages) check_packages ;;
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac
if (( fail )); then exit 1; fi
echo "ok"
