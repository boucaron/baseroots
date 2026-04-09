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

# Usage: ./build_crossbase_util-linux.sh <cross-compiler-prefix>
# Example: ./build_crossbase_util-linux.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/util-linux"
INSTALL_DIR="$BASE_DIR/initramfs/base"


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
  --prefix=/ \
  --disable-shared \
  --enable-static \
  --enable-libblkid \
  --enable-libuuid \
  --enable-libmount \
  --disable-nls \
  --disable-nsenter \
  --without-python \
  --without-systemd \
  --without-udev \
  --without-selinux \
  --without-tinfo \
  --without-readline \
  --without-ncurses \
  --disable-wall \
  --disable-mount \
  --disable-umount \
  --disable-fdisk \
  CC="${CROSS_PREFIX}cc -static" \
  CFLAGS="-O2" \
  LDFLAGS="-static -Wl,--gc-sections"

make V=1 -j"$JOBS_NUM"

# Install binaries into temporary dir
# make DESTDIR="$INSTALL_DIR" install

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

echo "[*] Installing util-linux into $CROSS_DIR/$INSTALL_CROSS_PREFIX"

make DESTDIR="$CROSS_DIR/$INSTALL_CROSS_PREFIX" install

echo "[+] util-linux installed (headers + static libs)"
