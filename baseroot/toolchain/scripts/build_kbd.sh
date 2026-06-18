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

#
# Usage: ./build_kbd.sh <cross-compiler-prefix>
# Example: ./build_kbd.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/kbd-2.9.0"
BUILD_DIR="$BASE_DIR/build/kbd"
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

# 2.10.0 as a dep that I cannot disable on xkbcommon (at this time)
if [ ! -d "$SRC_DIR" ]; then
    wget  https://git.kernel.org/pub/scm/linux/kernel/git/legion/kbd.git/snapshot/kbd-2.9.0.tar.gz
    cp -f kbd-2.9.0.tar.gz "$BASE_DIR/src" 
    cd "$BASE_DIR/src"
    tar xfz kbd-2.9.0.tar.gz
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

if [ ! -f "configure" ]; then
    echo "[*] Running autogen.sh to generate configure..."
    ./autogen.sh
fi


# Clean previous build artifacts
make distclean || true



# Configure for static cross-compilation
CC="${CROSS_PREFIX}cc -static"
AR="${CROSS_PREFIX}ar"
RANLIB="${CROSS_PREFIX}ranlib"
STRIP="${CROSS_PREFIX}strip"
CFLAGS="-static -O2"
LDFLAGS="-static"

./configure \
   --host="${CROSS_PREFIX%-}" \
   --prefix=/usr \
   --disable-vlock \
   --enable-static \
   --disable-shared \
   --without-bzip2 \
   --without-lzma \
   --disable-nls \
   CC="${CROSS_PREFIX}cc -static" \
   CFLAGS="-O2 -static" \
   LDFLAGS="-static -Wl,--gc-sections"
  
# Build main binaries 
make V=1 -j"$JOBS_NUM"


# Install binaries
#make V=1  DESTDIR="$INSTALL_DIR"  -n install


echo "[+] Base/kbd built and installed to $INSTALL_DIR."

