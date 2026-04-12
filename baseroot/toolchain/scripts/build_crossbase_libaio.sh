#!/bin/sh
set -e

# Dep for lvm2


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import common variables/functions from same directory as this script
COMMON_SH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "[!] Missing common.sh at $COMMON_SH"
    exit 1
fi

. "$COMMON_SH"


# Usage: ./build_crossbase_libuuid.sh <cross-compiler-prefix>
# Example: ./build_crossbase_libuuid.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/libaio-libaio-0.3.113"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    wget https://pagure.io/libaio/archive/libaio-0.3.113/libaio-libaio-0.3.113.tar.gz
    cp -f libaio-libaio-0.3.113.tar.gz  "$BASE_DIR/src/"
    cd "$BASE_DIR/src/"
    tar xfz libaio-libaio-0.3.113.tar.gz
    cd -
fi

# From LFS
case "$(uname -m)" in
  i?86) sed -e "s/off_t/off64_t/" -i harness/cases/23.t ;;
esac


cd "$SRC_DIR"
make clean || true

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"


make V=1 CC="$CC" CFLAGS="$CFLAGS -I. -fPIC"  LDFLAGS="-static -Wl,--gc-sections"  AR="$AR" RANLIB="$RANLIB" -j"$JOBS_NUM"


# Determine absolute path to cross-compiler directory
CROSS_CC_ABS="$(which "${CROSS_PREFIX}cc")"
if [ -z "$CROSS_CC_ABS" ]; then
    echo "[!] Cannot find cross-compiler ${CROSS_PREFIX}cc in PATH"
    exit 1
fi

CROSS_DIR="$(cd "$(dirname "$CROSS_CC_ABS")/.." && pwd)"  # parent of bin/ directory

# Path to cross prefix without trailing dash
INSTALL_CROSS_PREFIX="${CROSS_PREFIX%-}"

# Determine cross compiler root
CROSS_CC_ABS="$(which "${CROSS_PREFIX}cc")"
CROSS_DIR="$(cd "$(dirname "$CROSS_CC_ABS")/.." && pwd)"  # parent of bin/

# Install headers and static library
INSTALL_INCLUDE="$CROSS_DIR/$INSTALL_CROSS_PREFIX/include/uuid"
INSTALL_LIB="$CROSS_DIR/$INSTALL_CROSS_PREFIX/lib"

# INSTALL
make prefix="$CROSS_DIR/$INSTALL_CROSS_PREFIX" install

echo "[+] libaio headers and library installed under $CROSS_DIR/$INSTALL_CROSS_PREFIX"
cd -
