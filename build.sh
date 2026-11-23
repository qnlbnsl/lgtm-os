#!/usr/bin/env bash
# build.sh: build the LGTM OS ISO.
#
#   ./build.sh            full build -> out/lgtm-os-*.iso
#   ./build.sh packages   only build the local package repo
#
# Run as your normal user; it asks for sudo only for the final mkarchiso step.
# Needs: archiso, base-devel, git, curl.
#
# Note: AUR packages listed in aur.txt are built from their PKGBUILDs. Read those
# PKGBUILDs before building (cache/aur/<name>/PKGBUILD); they run on this machine.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
OUT=$ROOT/out
CACHE=$ROOT/cache
REPO=$OUT/repo           # repo used to build the ISO
ISOREPO=$OUT/isorepo     # repo shipped inside the ISO (offline extras)
PROFILE=$OUT/profile
RELENG=/usr/share/archiso/configs/releng

die() { echo "error: $*" >&2; exit 1; }
log() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

[[ $EUID -ne 0 ]] || die "run as a normal user (makepkg refuses root); sudo is used for the last step"
for c in makepkg repo-add git curl; do command -v $c >/dev/null || die "missing $c (install base-devel git curl)"; done

mkdir -p "$OUT" "$CACHE" "$REPO" "$ISOREPO"

add_to_repo() {  # add_to_repo DIR PKGFILES...
  local dir=$1; shift
  cp -f "$@" "$dir/"
  repo-add -q -R "$dir/lgtm.db.tar.gz" "${@/#*\//$dir/}" >/dev/null
}

build_local() {  # build_local NAME : one of our own packages/
  log "package: $1"
  local d=$OUT/pkgbuild/$1
  rm -rf "$d"; mkdir -p "$d"
  # Copy the PKGBUILD so the build tree stays out of the source tree; it reaches
  # integration/ through _src relative to the original location.
  cp "$ROOT/packages/$1"/* "$d/"
  sed -i "s|^_src=.*|_src=$ROOT/integration|; s|\"\$startdir/\$_src|\"\$_src|g" "$d/PKGBUILD"
  (cd "$d" && PKGDEST=$d makepkg -f --nodeps --noconfirm --cleanbuild >/dev/null)
  add_to_repo "$REPO" "$d"/*.pkg.tar.zst
}

build_aur() {  # build_aur NAME WHERE
  log "AUR: $1"
  local d=$CACHE/aur/$1
  if [[ -d $d/.git ]]; then git -C "$d" pull -q --ff-only; else git clone -q "https://aur.archlinux.org/$1.git" "$d"; fi
  # Not "$d/pkg": makepkg uses that path itself as its staging area.
  rm -rf "$d/out"; mkdir -p "$d/out"
  (cd "$d" && PKGDEST=$d/out makepkg -f --nodeps --noconfirm >/dev/null)
  local pkgs=("$d"/out/*.pkg.tar.zst)
  add_to_repo "$REPO" "${pkgs[@]}"
  [[ $2 == repo ]] && add_to_repo "$ISOREPO" "${pkgs[@]}"
  return 0
}

# Prints "TAG ASSET" for the newest GE-Proton release (or for LGTM_GEP_TAG).
# ASSET is the x86_64 tarball's base name; it gained an "-x86_64" suffix in GE-Proton11.
ge_proton_release() {
  local rel=latest
  [[ -n ${LGTM_GEP_TAG:-} ]] && rel=tags/$LGTM_GEP_TAG
  curl -fsSL "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/$rel" \
    | python -c '
import json, sys
r = json.load(sys.stdin)
names = [a["name"][:-7] for a in r["assets"] if a["name"].endswith(".tar.gz")]
pick = [n for n in names if n.endswith("-x86_64")] or [n for n in names if "aarch64" not in n]
if not pick: sys.exit("no x86_64 GE-Proton tarball in release " + r["tag_name"])
print(r["tag_name"], pick[0])'
}

stage_packages() {
  local gep; gep=$(ge_proton_release)
  export LGTM_GEP_TAG=${gep% *} LGTM_GEP_ASSET=${gep#* }
  log "GE-Proton: $LGTM_GEP_TAG ($LGTM_GEP_ASSET.tar.gz)"
  build_local lgtm-integration
  # Reuse a downloaded Proton tarball between builds.
  SRCDEST=$CACHE/src build_local lgtm-ge-proton
  while read -r name where; do
    [[ -z $name || $name == \#* ]] && continue
    build_aur "$name" "$where"
  done < "$ROOT/aur.txt"
}

stage_profile() {
  log "profile"
  [[ -d $RELENG ]] || die "archiso not installed (sudo pacman -S archiso)"
  rm -rf "$PROFILE"
  cp -r "$RELENG" "$PROFILE"
  rm -rf "$PROFILE/airootfs"
  cp -a "$ROOT/overlay/airootfs" "$PROFILE/airootfs"
  cp "$ROOT/packages.x86_64" "$PROFILE/packages.x86_64"
  local A=$PROFILE/airootfs

  # Offline extras repo inside the ISO.
  mkdir -p "$A/var/lib/lgtm"; cp -a "$ISOREPO" "$A/var/lib/lgtm/repo"

  # Enabled services (symlinks, so the installed system inherits them).
  local W=$A/etc/systemd/system
  mkdir -p "$W/multi-user.target.wants" "$W/sysinit.target.wants" "$W/sockets.target.wants"
  for s in iwd systemd-networkd systemd-resolved earlyoom lgtm-live; do
    local unit=/usr/lib/systemd/system/$s.service
    [[ $s == lgtm-live ]] && unit=/etc/systemd/system/lgtm-live.service
    ln -sf "$unit" "$W/multi-user.target.wants/$s.service"
  done
  ln -sf /usr/lib/systemd/system/systemd-timesyncd.service "$W/sysinit.target.wants/systemd-timesyncd.service"
  ln -sf /usr/lib/systemd/system/greetd.service "$W/display-manager.service"
  ln -sf /usr/lib/systemd/system/graphical.target "$W/default.target"
  ln -sf /run/systemd/resolve/stub-resolv.conf "$A/etc/resolv.conf"

  # Working mirrors for updates after install (the stock list is all commented out).
  mkdir -p "$A/etc/pacman.d"; cp /etc/pacman.d/mirrorlist "$A/etc/pacman.d/mirrorlist"

  # profiledef: name, faster-decompressing squashfs, script permissions.
  cat >> "$PROFILE/profiledef.sh" <<EOF

# --- LGTM OS ---
iso_name="lgtm-os"
iso_label="LGTM_\$(date --date="@\${SOURCE_DATE_EPOCH:-\$(date +%s)}" +%Y%m)"
iso_publisher="LGTM OS <https://github.com/qnlbnsl/lgtm-os>"
iso_application="LGTM OS live / install"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
# Replace releng's list: it names files from releng's airootfs, which we don't use.
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/lib/lgtm-live-setup"]="0:0:755"
)
EOF

  # Build-time pacman.conf: releng's + multilib + our local repo.
  cat >> "$PROFILE/pacman.conf" <<EOF

[multilib]
Include = /etc/pacman.d/mirrorlist

[lgtm]
SigLevel = Optional TrustAll
Server = file://$REPO
EOF

  # Boot entries: linux -> linux-zen, plus LGTM OS kernel options.
  local opts="copytoram=n quiet loglevel=3 zswap.enabled=0 nowatchdog"
  grep -rl 'vmlinuz-linux' "$PROFILE"/{grub,syslinux,efiboot} | while read -r f; do
    sed -i -e 's/vmlinuz-linux\b/vmlinuz-linux-zen/g' \
           -e 's/initramfs-linux\.img/initramfs-linux-zen.img/g' \
           -e "/archisobasedir=/ s/\$/ $opts/" "$f"
  done
  # Menu titles
  grep -rl 'Arch Linux' "$PROFILE"/{grub,syslinux,efiboot} | xargs -r sed -i 's/Arch Linux install medium/LGTM OS/g; s/Arch Linux/LGTM OS/g'
}

stage_iso() {
  log "mkarchiso (sudo)"
  sudo rm -rf "$OUT/work"
  sudo mkarchiso -v -w "$OUT/work" -o "$OUT" "$PROFILE"
  sudo rm -rf "$OUT/work"
  ls -lh "$OUT"/lgtm-os-*.iso
}

case ${1:-all} in
  packages) stage_packages ;;
  profile)  stage_profile ;;
  iso)      stage_profile; stage_iso ;;
  all)      stage_packages; stage_profile; stage_iso ;;
  *) die "usage: $0 [all|packages|profile|iso]" ;;
esac
