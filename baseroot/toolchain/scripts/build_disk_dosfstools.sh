#!/bin/sh
set -e

# Resolve script directory (portable, no realpath dependency)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import common variables/functions
COMMON_SH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "[!] Missing common.sh at $COMMON_SH"
    exit 1
fi
. "$COMMON_SH"

# Usage: ./build_disk_dosfstools.sh <cross-compiler-prefix>
# Example: ./build_disk_dosfstools.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/dosfstools"
BUILD_DIR="$BASE_DIR/build/dosfstools"
INSTALL_DIR="$BASE_DIR/initramfs/base"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Clone dosfstools if missing
if [ ! -d "$SRC_DIR" ]; then
    git clone https://github.com/dosfstools/dosfstools.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# Clean previous build artifacts
make distclean || true

# Set cross-compile env
CC="${CROSS_PREFIX}cc"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-static -O2"
LDFLAGS="-static"

if [ ! -f "configure" ]; then
   ./autogen.sh
fi

./configure --prefix=/usr            \
            --enable-compat-symlinks \
	    
# Build all binaries statically
make CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" -j"$JOBS_NUM"

# Copy binaries to initramfs
cd src
for bin in mkfs.fat fsck.fat fatlabel testdevinfo; do
    cp -f "$bin" "$INSTALL_DIR/sbin/$bin"
    $STRIP "$INSTALL_DIR/sbin/$bin" || true
done
cd -

echo "[+] Disk/dosfstools built and installed to $INSTALL_DIR/sbin"

