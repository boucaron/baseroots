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

# Usage: ./build_disk_xfsprogs.sh <cross-compiler-prefix>
# Example: ./build_disk_xfsprogs.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/xfsprogs"
BUILD_DIR="$BASE_DIR/build/xfsprogs"
INSTALL_DIR="$BASE_DIR/initramfs/base/"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# Configure for static cross-compilation
CC="${CROSS_PREFIX}cc"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
STRIP="${CROSS_PREFIX}strip"
CFLAGS="-static -O2"
LDFLAGS="-static"

# Clone xfsprogs if missing
if [ ! -d "$SRC_DIR" ]; then
   git clone https://git.kernel.org/pub/scm/fs/xfs/xfsprogs-dev.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# Clean previous build artifacts
make distclean || true

if [ ! -f "configure" ]; then
    echo "[*] Running autoreconf to generate configure..."
    autoreconf -fi
fi

# XFS_SUPER_MAGIC not found ?
# if so add that in linux/magic.h if not in the kernel include of
#  your cross compiler #define XFS_SUPER_MAGIC 0x58465342
# Better reinstall the kernel header from a fresh kernel well configured
# Example:  make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-musl- headers_install INSTALL_HDR_PATH=~/baseroots/baseroot/toolchain/output/x86_64-musl/x86_64-linux-musl
#

./configure \
    --host="${CROSS_PREFIX%-}" \
    --prefix=/usr \
    --enable-scrub=no \
    --enable-shared=no \
    --enable-static=yes \
    --enable-lto=no \
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Build main binaries (mkfs.xfs, xfs_repair, xfs_info, etc.)
make -j"$JOBS_NUM"

# I hate libtool...
cd mkfs
rm -f mkfs.xfs
STATIC_LIBS="../libxfs/.libs/libxfs.a ../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a"
$CC -static -static-libgcc -Wl,--gc-sections proto.o xfs_mkfs.o $STATIC_LIBS -lrt -lblkid -luuid -linih -lurcu -lpthread -o mkfs.xfs
$STRIP mkfs.xfs
cd -

# Install binaries into temporary dir
# make DESTDIR="$INSTALL_DIR" install

echo "[+] Disk/xfsprogs built and installed to $INSTALL_DIR."

