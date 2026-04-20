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
# Usage: ./build_network_dropbear.sh <cross-compiler-prefix>
# Example: ./build_network_dropbear.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/dropbear-2025.89"
BUILD_DIR="$BASE_DIR/build/dropbear"
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
    wget https://dropbear.nl/mirror/releases/dropbear-2025.89.tar.bz2
    cp -f dropbear-2025.89.tar.bz2 "$BASE_DIR/src" 
    cd "$BASE_DIR/src"
    tar xfj dropbear-2025.89.tar.bz2
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
make distclean || true


CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"


./configure \
   --host="${CROSS_PREFIX%-}" \
   --prefix=/usr \
   --with-openssl="$CROSS_DIR/$INSTALL_CROSS_PREFIX/usr" \
   --disable-shared \
   --disable-loginfunc \
   --disable-utmp \
   --disable-utmpx \
   --disable-wtmp \
   --disable-wtmpx \
   CC="${CROSS_PREFIX}cc -static" \
   CFLAGS="-O2" \
   LDFLAGS="-static -Wl,--gc-sections"
 
# Build main binaries 
make V=1 -j"$JOBS_NUM" PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1

#"$STRIP" dropbearkey
#"$STRIP" dropbearconvert
#"$STRIP" dbclient
#"$STRIP" dropbear
"$STRIP" dropbearmulti
#"$STRIP" scp

# Install binaries
#make V=1  DESTDIR="$INSTALL_DIR"  -n install
#cp -f dropbearkey $INSTALL_DIR/usr/bin
#cp -f dropbearconvert $INSTALL_DIR/usr/bin
#cp -f dbclient $INSTALL_DIR/usr/bin
#cp -f scp $INSTALL_DIR/usr/bin
#cp -f dropbear $INSTALL_DIR/usr/sbin
cp -f dropbearmulti $INSTALL_DIR/usr/sbin


echo "[+] Network/dropbear built and installed to $INSTALL_DIR."

