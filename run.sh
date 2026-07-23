#!/usr/bin/env bash
# QEMU baslatma scripti: bulbul-live ISO'sunu KVM hizlandirmali (varsa) calistirir.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO="${1:-$PROJECT_DIR/binary.iso}"
RAM_MB="${QEMU_RAM:-2048}"
SMP="${QEMU_SMP:-2}"
MONITOR_PORT="${QEMU_MONITOR_PORT:-4444}"
SERIAL_SOCK="${QEMU_SERIAL_SOCK:-/tmp/serial.sock}"
PERSIST_IMG="${QEMU_PERSIST_IMG:-$PROJECT_DIR/persist.qcow2}"

if [ ! -f "$ISO" ]; then
    echo "HATA: ISO bulunamadi: $ISO" >&2
    exit 1
fi

# RAM kisiti: ayni anda birden fazla QEMU sureci host'u tikatabilir (bkz proje notlari).
# pgrep -f kendi cagrisiyla da eslesebildigi icin sonucu filtreliyoruz.
RUNNING="$(pgrep -fa qemu-system-x86_64 | grep -v 'pgrep -fa' || true)"
if [ -n "$RUNNING" ]; then
    echo "HATA: zaten calisan bir qemu-system-x86_64 sureci var, once onu kapatin:" >&2
    echo "$RUNNING" >&2
    exit 1
fi

ACCEL_ARGS=()
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL_ARGS=(-enable-kvm -cpu host)
    echo "KVM hizlandirma aktif."
else
    ACCEL_ARGS=(-accel tcg -cpu qemu64)
    echo "UYARI: /dev/kvm erisilemiyor, yazilimsal (TCG) emulasyona dusuluyor (yavas olacak)."
    echo "       Duzeltmek icin: sudo usermod -aG kvm \"\$USER\" ve ardindan WSL oturumunu yeniden baslatin (wsl.exe --terminate <dagitim>)."
fi

rm -f "$SERIAL_SOCK"

PERSIST_ARGS=()
if [ -f "$PERSIST_IMG" ]; then
    PERSIST_ARGS=(-drive file="$PERSIST_IMG",if=none,id=persist0,format=qcow2 -device virtio-blk-pci,drive=persist0,serial=bulbulpersist)
    echo "Persist: $PERSIST_IMG (guest icinde /home/bulbul/Persistent altina otomatik mount edilir)"
else
    echo "UYARI: kalici disk bulunamadi ($PERSIST_IMG), kalici depolama olmadan baslatiliyor."
fi

echo "ISO:    $ISO"
echo "RAM:    ${RAM_MB}MB   SMP: $SMP"
echo "Monitor: telnet 127.0.0.1:$MONITOR_PORT"
echo "Serial:  unix socket $SERIAL_SOCK (root console, for scripted access)"
echo

exec qemu-system-x86_64 \
    -m "$RAM_MB" \
    -smp "$SMP" \
    "${ACCEL_ARGS[@]}" \
    -cdrom "$ISO" \
    -boot d \
    -usb -device usb-tablet \
    -no-reboot \
    "${PERSIST_ARGS[@]}" \
    -serial unix:"$SERIAL_SOCK",server,nowait \
    -monitor telnet:127.0.0.1:"$MONITOR_PORT",server,nowait
