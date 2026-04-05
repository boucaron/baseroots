#!/bin/sh
set -e

# Resolve script directory (portable, no realpath dependency)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import common variables/functions from same directory as this script
COMMON_SH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "[!] Missing common.sh at $COMMON_SH"
    exit 1
fi

. "$COMMON_SH"

# Usage: ./build_toybox.sh <cross-compiler-prefix>
# Example: ./build_toybox.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/toybox"
BUILD_DIR="$BASE_DIR/build/toybox"
INSTALL_DIR="$BASE_DIR/initramfs/base/bin"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

cd "$SRC_DIR"

# Clone Toybox if missing
if [ ! -d "$SRC_DIR" ]; then
    git clone https://github.com/landley/toybox.git "$SRC_DIR"
fi

TOYBOX_CONFIG="$SCRIPT_DIR/toybox_config"
if [ ! -f "$TOYBOX_CONFIG" ]; then
    echo "[!] Missing toybox_config at $TOYBOX_CONFIG"
    exit 1
fi

cp -f $TOYBOX_CONFIG $SRC_DIR/.config
echo "Custom toybox_config copied"

# Clean previous build
echo `pwd`
make clean || true

# Export cross-compiler
export CC="${CROSS_PREFIX}gcc"
export CFLAGS="-Os -static"
export PREFIX="$INSTALL_DIR"

# Build Toybox
make oldconfig
# make menuconfig
make -j"$JOBS_NUM"

# Install binary
rm -f $INSTALL_DIR/toybox
cp toybox "$INSTALL_DIR"

# Dynamically generate symlinks based on the binary itself
cd "$INSTALL_DIR"

# Remove any old symlinks first
find . -maxdepth 1 -type l -exec rm -f {} \;

# Extract commands from commands.h (host-safe)
CONFIG_FILE="$SRC_DIR/.config"
echo "[*] Creating symlinks based on .config"
grep '^CONFIG_[A-Z]' "$CONFIG_FILE" \
    | grep '=y$' \
    | grep -v '^CONFIG_TOYBOX_' \
    | while read line; do
        # Extract command name
        cmd=$(echo "$line" | sed 's/^CONFIG_\(.*\)=y/\1/' | tr 'A-Z' 'a-z')
        [ "$cmd" = "toybox" ] && continue
        echo "[*] Creating symlink: $cmd -> toybox"
        ln -sf toybox "$cmd"
    done


echo "[+] Toybox built and installed to $INSTALL_DIR with all enabled commands."

