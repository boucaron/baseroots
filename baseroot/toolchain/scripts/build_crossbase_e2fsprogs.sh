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

# Usage: ./build_crossbase_e2fsprogs.sh <cross-compiler-prefix>
# Example: ./build_crossbase_e2fsprogs.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/e2fsprogs"
INSTALL_DIR="$BASE_DIR/initramfs/base"


# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git "$SRC_DIR"
fi

cd "$SRC_DIR"
make distclean || true

# Configure for static cross-compilation
# Using default prefix for install (bin into $INSTALL_DIR)
CC="${CROSS_PREFIX}cc"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
CFLAGS="-static -O2"
LDFLAGS="-static"

./configure \
    --host="${CROSS_PREFIX%-}" \
    --prefix=/ \
    --sysconfdir=/etc \
    --disable-nls \
    --disable-libblkid \
    --disable-libuuid \
    --disable-uuidd \
    --enable-libuuid \
    --enable-libblkid \
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Build only the main binaries (like mkfs, fsck, tune2fs)
make -j"$JOBS_NUM"

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

echo "[*] Installing e2fsprogs into $CROSS_DIR/$INSTALL_CROSS_PREFIX"

make DESTDIR="$CROSS_DIR/$INSTALL_CROSS_PREFIX" install

echo "[+] e2fsprogs installed (headers + static libs)"
