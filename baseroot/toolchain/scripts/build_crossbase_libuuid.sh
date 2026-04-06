#!/bin/sh
set -e

# Dependency needed for xfsprogs to be installed in your cross compiler base


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
SRC_DIR="$BASE_DIR/src/util-linux"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    git clone --depth=1 https://github.com/util-linux/util-linux.git "$SRC_DIR"
fi

cd "$SRC_DIR"
make distclean || true

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"

if [ ! -f "configure" ]; then
   ./autogen.sh
fi

./configure \
  --host="${CROSS_PREFIX%-}" \
  --prefix=/usr \
  --disable-shared \
  --enable-static \
  --enable-libblkid \
  --enable-libuuid \
  --enable-libmount \
  --enable-static-programs=fdisk,losetup,mount,umount \
  --disable-nls \
  --without-python \
  --without-systemd \
  --without-udev \
  --without-selinux \
  --without-tinfo \
  --without-readline \
  --without-ncurses \
  CC="${CROSS_PREFIX}cc -static" \
  CFLAGS="-O2" \
  LDFLAGS="-static -Wl,--gc-sections"

make -j"$JOBS_NUM"


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

# Ensure uuid subdirectory exists
mkdir -p "$INSTALL_INCLUDE"

# Copy static library and headers
cp -f .libs/libuuid.a "$INSTALL_LIB/"
cp -f libuuid/src/uuid.h "$INSTALL_INCLUDE/"

echo "[+] libuuid headers and library installed under $CROSS_DIR/$INSTALL_CROSS_PREFIX"
cd -
