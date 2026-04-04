#!/bin/sh
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/toybox"
BUILD_DIR="$BASE_DIR/build/toybox"
INSTALL_DIR="$BASE_DIR/initramfs/base/bin"

echo "[*] Cleaning Toybox build and install"

# Remove build artifacts
rm -rf "$BUILD_DIR"

# Remove Toybox binary
rm -f "$INSTALL_DIR/toybox"

# Remove all symlinks pointing to Toybox
cd "$INSTALL_DIR"
find . -maxdepth 1 -type l -exec rm -f {} \;

echo "[+] Toybox clean complete"

