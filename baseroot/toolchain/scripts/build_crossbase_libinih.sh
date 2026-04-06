#!/bin/sh
set -e

# Dependency needed for xfsprogs to be installed in your cross compiler base

# Usage: ./build_crossbase_libinih.sh <cross-compiler-prefix>
# Example: ./build_crossbase_libinih.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

# Directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src/libinih"

# Clone libinih if missing
if [ ! -d "$SRC_DIR" ]; then
    echo "[*] Cloning libinih..."
    git clone https://github.com/benhoyt/inih.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# Compile ini.c into a static library
mkdir -p build && cd build

CC="${CROSS_PREFIX}cc"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
CFLAGS="-static -O2"

echo "[*] Building libinih..."
$CC $CFLAGS -c ../ini.c -o ini.o
$AR rcs libinih.a ini.o

# Determine absolute path to cross-compiler directory
CROSS_CC_ABS="$(which "${CROSS_PREFIX}cc")"
if [ -z "$CROSS_CC_ABS" ]; then
    echo "[!] Cannot find cross-compiler ${CROSS_PREFIX}cc in PATH"
    exit 1
fi

CROSS_DIR="$(cd "$(dirname "$CROSS_CC_ABS")/.." && pwd)"  # parent of bin/ directory

# Remove trailing dash from CROSS_PREFIX for actual path
INSTALL_CROSS_PREFIX="${CROSS_PREFIX%-}"

# CROSS_DIR points to the root of the cross compiler environment
# Just copy headers and library; directories are assumed to exist
cp -f ../ini.h "$CROSS_DIR/$INSTALL_CROSS_PREFIX/include/"
cp -f libinih.a "$CROSS_DIR/$INSTALL_CROSS_PREFIX/lib/"

echo "[+] libinih built and installed under $CROSS_DIR/$INSTALL_CROSS_PREFIX"

cd -
