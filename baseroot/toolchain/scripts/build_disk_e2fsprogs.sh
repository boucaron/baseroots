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

# Usage: ./build_disk_e2fsprogs.sh <cross-compiler-prefix>
# Example: ./build_disk_e2fsprogs.sh x86_64-linux-musl-


CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi


BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/e2fsprogs"
BUILD_DIR="$BASE_DIR/build/e2fsprogs"
INSTALL_DIR="$BASE_DIR/initramfs/base/"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# Clone Toybox if missing
if [ ! -d "$SRC_DIR" ]; then
   git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# Clean previous build artifacts
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
    --prefix=/usr \
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
make DESTDIR="$INSTALL_DIR" install

# Manual cleanup
# TODO: Remove include, share, libexec, lib



echo "[+] Disk/e2fsprogs built and installed to $INSTALL_DIR."


