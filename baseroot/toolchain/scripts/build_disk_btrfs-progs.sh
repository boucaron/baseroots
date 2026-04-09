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

# ==> Depends on e2fsprogs, zlib, zstd ==> incomplete for e2fsprogs lib
# ==> Disabled for the moment lzo, libudev 
#
# Usage: ./build_disk_btrfs-progs.sh <cross-compiler-prefix>
# Example: ./build_disk_btrfs-progs.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/btrfs-progs"
BUILD_DIR="$BASE_DIR/build/btrfs-progs"
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

# Clone btrfs-progs if missing
if [ ! -d "$SRC_DIR" ]; then
   git clone https://git.kernel.org/pub/scm/linux/kernel/git/kdave/btrfs-progs.git "$SRC_DIR"
fi

cd "$SRC_DIR"


# Determine absolute path to cross-compiler directory
CROSS_CC_ABS="$(which "${CROSS_PREFIX}cc")"
[ -z "$CROSS_CC_ABS" ] && {
    echo "[!] Cannot find ${CROSS_PREFIX}cc in PATH"
    exit 1
}

CROSS_DIR="$(cd "$(dirname "$CROSS_CC_ABS")/.." && pwd)"


INSTALL_CROSS_PREFIX="${CROSS_PREFIX%-}"

INSTALL_INCLUDE="$CROSS_DIR/$INSTALL_CROSS_PREFIX/include"
INSTALL_LIB="$CROSS_DIR/$INSTALL_CROSS_PREFIX/lib"

# Clean previous build artifacts
make clean || true

if [ ! -f "configure" ]; then
    echo "[*] Running autoreconf to generate configure..."
    autoreconf -fi
fi


EXT2FS_LIBS="-static -L$SRC_DIR\ext2fs\lib -lext2fs -lcom_err -lss -lz"
EXT2FS_CFLAGS="$CFLAGS"
BLKID_LIBS="-L$INSTALL_LIB -lblkid -luuid -lz"
BLKID_CFLAGS="-I$INSTALL_INCLUDE"
./configure \
    --host="${CROSS_PREFIX%-}" \
    --prefix=/usr \
    --enable-shared=no \
    --enable-static=yes \
    --disable-backtrace \
    --disable-documentation \
    --disable-lzo \
    --disable-libudev \
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    EXT2FS_LIBS="$EXT2FS_LIBS" \
    EXT2FS_CFLAGS="$EXT2FS_CFLAGS" \
    BLKID_LIBS="$BLKID_LIBS" \
    BLKID_CFLAGS="$BLKID_CFLAGS"
    

# Build main binaries (mkfs.xfs, xfs_repair, xfs_info, etc.)
make V=1 -j"$JOBS_NUM"


# Install binaries

$STRIP  mkfs.btrfs \
   btrfs-map-logical \
   btrfs-image \
   btrfs-find-root \
   btrfstune \
   btrfs-select-super \
   btrfs-convert \
   btrfs-corrupt-block \
   btrfs

cp -f mkfs.btrfs \
   btrfs-map-logical \
   btrfs-image \
   btrfs-find-root \
   btrfstune \
   btrfs-select-super \
   btrfs-convert \
   btrfs-corrupt-block \
   btrfs \
   "$INSTALL_DIR"/usr/bin

cd  "$INSTALL_DIR"/usr/bin
ln -s btrfs btrfsck
cd -

echo "[+] Disk/btrfs-progs built and installed to $INSTALL_DIR."

