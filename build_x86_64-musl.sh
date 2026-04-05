#!/bin/sh

set -e  # Exit immediately on any command failure

TARGET_ARCH_LIBC=x86_64-musl
TARGET_CROSS_ARCH_LIBC=x86_64-linux-musl-

# Build cross compiler with libc
./baseroot/toolchain/scripts/build.sh "$TARGET_ARCH_LIBC" \
  || { echo "[!] Failed: build.sh"; exit 1; }

# Build toybox
./baseroot/toolchain/scripts/build_toybox.sh "$TARGET_CROSS_ARCH_LIBC" \
  || { echo "[!] Failed: build_toybox.sh"; exit 1; }

# Build bash
./baseroot/toolchain/scripts/build_bash.sh "$TARGET_CROSS_ARCH_LIBC" \
  || { echo "[!] Failed: build_bash.sh"; exit 1; }

# Build initrd
cd baseroot/toolchain/initramfs/base \
  || { echo "[!] Failed: cd into initramfs/base"; exit 1; }

find . | cpio -H newc -o > ../base.cpio \
  || { echo "[!] Failed: creating cpio archive"; exit 1; }

cd - >/dev/null \
  || { echo "[!] Failed: cd back"; exit 1; }

echo "[+] Done: Initrd ready"
