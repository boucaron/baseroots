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

# Usage: ./build_crossbase_openssl.sh <cross-compiler-prefix>
# Example: ./build_crossbase_openssl.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/openssl-3.6.2"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    wget https://github.com/openssl/openssl/releases/download/openssl-3.6.2/openssl-3.6.2.tar.gz
    mv openssl-3.6.2.tar.gz "$BASE_DIR/src"
    cd "$BASE_DIR/src"
    tar xfz openssl-3.6.2.tar.gz
    cd -
fi

cd "$SRC_DIR"

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"

# Configure for static cross-compilation
./config linux-x86_64 \
  no-shared \
  no-tests \
  --cross-compile-prefix="${CROSS_PREFIX}" \
  --prefix=/usr -static

# Build
make V=1 -j"$JOBS_NUM"



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

echo "[*] Installing openssl into $CROSS_DIR/$INSTALL_CROSS_PREFIX"


make V=1 DESTDIR="$CROSS_DIR/$INSTALL_CROSS_PREFIX"  install

echo "[+] openssl installed (headers + static libs)"
