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

# Usage: ./build_editor_joe.sh <cross-compiler-prefix>
# Example: ./build_editor_joe.sh x86_64-linux-musl-


CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi


BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_BASE="$BASE_DIR/src"
SRC_DIR="$BASE_DIR/src/joe-releases-joe-4.8"
BUILD_DIR="$BASE_DIR/build/joe"
INSTALL_DIR="$BASE_DIR/initramfs/base/"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# Clone Toybox if missing
if [ ! -d "$SRC_DIR" ]; then
   cd "$SRC_BASE"
   wget https://github.com/joe-editor/joe/archive/refs/tags/releases/joe-4.8.tar.gz
   tar xfz joe-4.8.tar.gz
   cd -
fi

cd "$SRC_DIR"
if [ ! -f "configure" ]; then
    ./autojoe
    # //			stdin = fopen("/dev/tty", "rb");
   #			freopen("/dev/tty", "r", stdin);
fi

./configure \
  --host="${CROSS_PREFIX%-}" \
  --prefix="$INSTALL_DIR/usr" \
  --disable-curses \
  --disable-termcap \
  CC="${CROSS_PREFIX}cc -static" \
  CFLAGS="-O2" \
  LDFLAGS="-static -Wl,--gc-sections"

make V=1 -j"$JOBS_NUM"

make V=1 install

echo "[+] editor/joe built and installed to $INSTALL_DIR."
