#!/usr/bin/env bash
# tools/vm.sh: boot LGTM OS in QEMU to check speed and memory.
#
#   tools/vm.sh live [MB]      boot the ISO (default 128 MB)
#   tools/vm.sh install [MB]   boot the ISO with a blank 20 GB disk attached
#   tools/vm.sh disk [MB]      boot the installed disk (default 128 MB)
#
# Set UEFI=1 to boot with OVMF (edk2-ovmf). Inside the VM, run lgtm-mem.
set -euo pipefail
cd "$(dirname "$0")/.."
iso=$(ls -t out/lgtm-os-*.iso 2>/dev/null | head -n1 || true)
disk=out/vm-disk.qcow2
mode=${1:-live}; mem=${2:-128}
args=(-enable-kvm -cpu host -smp 2 -m "$mem" -device virtio-vga -display gtk
      -nic user,model=virtio-net-pci -device virtio-tablet -serial mon:stdio)
if [[ ${UEFI:-0} == 1 ]]; then
  cp -n /usr/share/edk2/x64/OVMF_VARS.4m.fd out/OVMF_VARS.fd 2>/dev/null || true
  args+=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd
         -drive if=pflash,format=raw,file=out/OVMF_VARS.fd)
fi
case $mode in
  live)    exec qemu-system-x86_64 "${args[@]}" -cdrom "$iso" ;;
  install) [[ -e $disk ]] || qemu-img create -f qcow2 "$disk" 20G
           exec qemu-system-x86_64 "${args[@]}" -cdrom "$iso" -drive file="$disk",if=virtio -boot d ;;
  disk)    exec qemu-system-x86_64 "${args[@]}" -drive file="$disk",if=virtio ;;
  *) sed -n '2,9p' "$0"; exit 2 ;;
esac
