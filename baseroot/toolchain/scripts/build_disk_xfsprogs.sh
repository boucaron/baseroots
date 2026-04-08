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

cd growfs
STATIC_LIBS="../libxfs/.libs/libxfs.a ../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a"
$CC -static -static-libgcc -Wl,--gc-sections xfs_growfs.o $STATIC_LIBS -lrt -lblkid -luuid -linih -lurcu -lpthread -o xfs_growfs
$STRIP xfs_growfs
cd -

cd fsr
STATIC_LIBS="../libhandle/.libs/libhandle.a ../libfrog/.libs/libfrog.a"
$CC -static -static-libgcc -Wl,--gc-sections xfs_fsr.o $STATIC_LIBS -lrt -lblkid -luuid -linih -lurcu -lpthread -o xfs_fsr
$STRIP xfs_fsr
cd -

cd copy
STATIC_LIBS="../libxfs/.libs/libxfs.a ../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a ../libxlog/.libs/libxlog.a"
$CC -static -static-libgcc -Wl,--gc-sections xfs_copy.o $STATIC_LIBS -lrt -lblkid -luuid -linih -lurcu -lpthread -o xfs_copy
$STRIP xfs_copy
cd -


cd spaceman
STATIC_LIBS="../libhandle/.libs/libhandle.a ../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a"
$CC -static -static-libgcc -Wl,--gc-sections file.o health.o info.o init.o prealloc.o trim.o freesp.o $STATIC_LIBS -o xfs_spaceman
$STRIP xfs_spaceman
cd -

cd quota
STATIC_LIBS="../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a"
$CC -static -static-libgcc -Wl,--gc-sections init.o util.o edit.o free.o linux.o path.o project.o quot.o quota.o report.o state.o $STATIC_LIBS -o xfs_quota
$STRIP xfs_quota
cd -

cd logprint
STATIC_LIBS="../libxfs/.libs/libxfs.a ../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a ../libxlog/.libs/libxlog.a"
$CC -static -static-libgcc -Wl,--gc-sections logprint.o log_copy.o log_dump.o log_misc.o log_print_all.o log_print_trans.o log_redo.o $STATIC_LIBS -lrt -lblkid -luuid -linih -lurcu -lpthread -o xfs_logprint
$STRIP xfs_logprint
cd -

cd io
STATIC_LIBS="../libxcmd/.libs/libxcmd.a ../libfrog/.libs/libfrog.a ../libhandle/.libs/libhandle.a"
$CC -static -static-libgcc -Wl,--gc-sections aginfo.o attr.o bmap.o bulkstat.o cowextsize.o crc32cselftest.o encrypt.o exchrange.o fadvise.o fiemap.o file.o freeze.o fsproperties.o fsuuid.o fsync.o getrusage.o imap.o init.o inject.o label.o link.o madvise.o mincore.o mmap.o open.o parent.o pread.o prealloc.o pwrite.o readdir.o reflink.o resblks.o scrub.o seek.o sendfile.o shutdown.o stat.o swapext.o sync.o sync_file_range.o truncate.o utimes.o copy_file_range.o cachestat.o fsmap.o $STATIC_LIBS  -luuid -lpthread -o xfs_io
$STRIP xfs_io
cd -




# Install binaries into temporary dir
# make DESTDIR="$INSTALL_DIR" install

echo "[+] Disk/xfsprogs built and installed to $INSTALL_DIR."

