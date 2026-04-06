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
SRC_INI_DIR="$BASE_DIR/src/libinih"
SRC_DIR="$BASE_DIR/src/xfsprogs"
BUILD_DIR="$BASE_DIR/build/xfsprogs"
INSTALL_DIR="$BASE_DIR/initramfs/base/"

# Ensure directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

# Configure for static cross-compilation
CC="${CROSS_PREFIX}cc"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
CFLAGS="-static -O2"
LDFLAGS="-static"

# Add dep
# Clone ini lib 
if [ ! -d "$SRC_INI_DIR" ]; then
    git clone https://github.com/benhoyt/inih.git "$SRC_INI_DIR"
    # Manually compile and generate the archive and include
    
fi

cd "$SRC_INI_DIR"

# Compile ini.c into a static library
mkdir -p build && cd build
$CC $CFLAGS -c ../ini.c -o ini.o
$AR rcs libinih.a ini.o

# Install headers and static library directly into cross-prefix
mkdir -p "$CROSS_PREFIX/include" "$CROSS_PREFIX/lib"
cp -f ../ini.h "$CROSS_PREFIX/include/"
cp -f libinih.a "$CROSS_PREFIX/lib/"

echo "[+] libinih built and installed directly under $CROSS_PREFIX"

cd -


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

# Absolute paths for libinih
ABS_INI_INCLUDE="$(cd "$BASE_DIR/src/libinih/build/$CROSS_PREFIX/include" && pwd)"
ABS_INI_LIB="$(cd "$BASE_DIR/src/libinih/build/$CROSS_PREFIX/lib" && pwd)"
echo "ABS_INI_INCLUDE = $ABS_INI_INCLUDE"
echo "ABS_INI_LIB = $ABS_INI_LIB"

CPPFLAGS="-I$ABS_INI_INCLUDE"
LDFLAGS="-L$ABS_INI_LIB -static"
./configure \
    --host="${CROSS_PREFIX%-}" \
    --prefix=/usr \
    --disable-nls \
    --disable-debug \
    CC="$CC $CPPFLAGS" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

# Build main binaries (mkfs.xfs, xfs_repair, xfs_info, etc.)
make -j"$JOBS_NUM"

# Install binaries into temporary dir
# make DESTDIR="$INSTALL_DIR" install

echo "[+] Disk/xfsprogs built and installed to $INSTALL_DIR."

