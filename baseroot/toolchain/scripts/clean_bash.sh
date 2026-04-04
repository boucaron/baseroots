#!/bin/sh
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$BASE_DIR/build/bash"
INSTALL_DIR="$BASE_DIR/initramfs/base"

echo "[*] Cleaning Bash build and install"

# Remove build artifacts
rm -rf "$BUILD_DIR"

# Remove installed binaries
rm -f "$INSTALL_DIR/usr/bin/bash" "$INSTALL_DIR/bin/sh"

echo "[+] Bash clean complete"
