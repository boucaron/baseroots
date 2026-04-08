#!/bin/sh
set -e

# Dependency needed for btrfs-tools to be installed in your cross compiler base

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import common variables/functions from same directory as this script
COMMON_SH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "[!] Missing common.sh at $COMMON_SH"
    exit 1
fi

. "$COMMON_SH"

# Usage: ./build_crossbase_zstd.sh <cross-compiler-prefix>
# Example: ./build_crossbase_zstd.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/zstd-1.5.7"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    wget https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
    mv zstd-1.5.7.tar.gz "$BASE_DIR/src"
    cd "$BASE_DIR/src"
    tar xfz zstd-1.5.7.tar.gz
    cd -
fi

cd "$SRC_DIR"
make clean || true

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"


# Configure for static cross-compilation
CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="-static -Wl,--gc-sections" AR="${CROSS_PREFIX}ar" RANLIB="${CROSS_PREFIX}ranlib" V=1 make -j"$JOBS_NUM"


# Determine absolute path to cross-compiler directory
CROSS_CC_ABS="$(which "${CROSS_PREFIX}cc")"
[ -z "$CROSS_CC_ABS" ] && {
    echo "[!] Cannot find ${CROSS_PREFIX}cc in PATH"
    exit 1
}

CROSS_DIR="$(cd "$(dirname "$CROSS_CC_ABS")/.." && pwd)"

# Remove trailing dash from CROSS_PREFIX
INSTALL_CROSS_PREFIX="${CROSS_PREFIX%-}"

INSTALL_INCLUDE="$CROSS_DIR/$INSTALL_CROSS_PREFIX/include"
INSTALL_LIB="$CROSS_DIR/$INSTALL_CROSS_PREFIX/lib"

echo "[*] Installing zlib into $CROSS_DIR/$INSTALL_CROSS_PREFIX"

cp -f lib/zstd.h "$INSTALL_INCLUDE"
cp -f lib/zdict.h "$INSTALL_INCLUDE"
cp -f lib/zstd_errors.h "$INSTALL_INCLUDE"
cp -f lib/libzstd.a "$INSTALL_LIB"

echo "[+] zstd installed (headers + static libs)"
