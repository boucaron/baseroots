#!/bin/sh

set -e  # Exit immediately on any command failure

TARGET_ARCH_LIBC=x86_64-musl
TARGET_CROSS_ARCH_LIBC=x86_64-linux-musl-

# Build cross compiler with libc
./baseroot/toolchain/scripts/build.sh "$TARGET_ARCH_LIBC" \
  || { echo "[!] Failed: build.sh"; exit 1; }

TOOLCHAIN_BIN="$(pwd)/baseroot/toolchain/output/x86_64-musl/bin"

# Check if the directory exists
if [ ! -d "$TOOLCHAIN_BIN" ]; then
    echo "Error: Toolchain bin directory not found: $TOOLCHAIN_BIN" >&2
    return 1 2>/dev/null || exit 1
fi

# Add to PATH
export PATH="$TOOLCHAIN_BIN:$PATH"

# Check if the compiler exists
if ! command -v x86_64-linux-musl-cc >/dev/null 2>&1; then
    echo "Error: x86_64-linux-musl-cc not found in PATH" >&2
    return 1 2>/dev/null || exit 1
fi

# Get target triplet
TARGET_TRIPLET=$(x86_64-linux-musl-cc -dumpmachine 2>/dev/null)
if [ -z "$TARGET_TRIPLET" ]; then
    echo "Error: Could not determine target triplet from compiler" >&2
    return 1 2>/dev/null || exit 1
fi

echo "Toolchain ready. Target triplet: $TARGET_TRIPLET"

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
