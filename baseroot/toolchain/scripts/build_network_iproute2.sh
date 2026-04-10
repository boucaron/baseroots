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
SRC_DIR="$BASE_DIR/src/iproute2-6.19.0"
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
    wget  https://git.kernel.org/pub/scm/network/iproute2/iproute2.git/snapshot/iproute2-6.19.0.tar.gz
    cp -f iproute2-6.19.0.tar.gz "$BASE_DIR/src" 
    cd "$BASE_DIR/src"
    tar xfz iproute2-6.19.0.tar.gz
    cd -
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

# Steps from LFS
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8



  CC="$CC" \
  AR="$AR" \
  RANLIB="$RANLIB" \
  HAVE_CAP=no \
  HAVE_HELP=no \
  HAVE_MNL=no \
  ./configure --color never  --prefix=/usr

sed -i 's/HAVE_CAP:=y/HAVE_CAP:=n/' config.mk
sed -i 's/-DHAVE_LIBCAP//g' config.mk
sed -i 's/HAVE_ELF:=y/HAVE_ELF:=n/' config.mk
sed -i 's/CFLAGS += -DHAVE_ELF -DWITH_GZFILEOP//g' config.mk
sed -i 's/HAVE_SELINUX:=y/HAVE_SELINUX:=n/' config.mk
sed -i 's/CFLAGS += -DHAVE_SELINUX//g' config.mk

sed -i 's/LDLIBS += -lcap//g' config.mk
sed -i 's/LDLIBS +=  -lelf//g' config.mk
sed -i 's/LDLIBS += -lselinux//g' config.mk

sed -i '1i #include <linux/types.h>' include/color.h

  
# Build main binaries 
make V=1 -j"$JOBS_NUM"


# Install binaries

# TODO

echo "[+] Network/iproute2 built and installed to $INSTALL_DIR."

