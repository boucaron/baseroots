#!/bin/sh
set -e

# Usage: ./build_bash.sh <cross-compiler-prefix>
CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/bash"
BUILD_DIR="$BASE_DIR/build/bash"
INSTALL_DIR="$BASE_DIR/initramfs/base"

# Check source exists
if [ ! -d "$SRC_DIR" ]; then
    echo "[!] Bash source not found in $SRC_DIR"
    exit 1
fi

mkdir -p "$BUILD_DIR" "$INSTALL_DIR/bin"

cd "$SRC_DIR"

# Clean previous build
make distclean || true

# Derive host from CROSS_PREFIX
# Example: x86_64-linux-musl- => x86_64-linux-musl
HOST="${CROSS_PREFIX%-}"  

echo "[*] Building Bash for host: $HOST"

# Configure for static build
./configure --prefix=/usr \
            --host="$HOST" \
	    --without-bash-malloc \
            --enable-static-link \
            --disable-nls \
	    --without-libintl-prefix \
            CC="${CROSS_PREFIX}gcc" \
            CFLAGS="-Os -static"

# Build and install
make -j8
make install DESTDIR="$INSTALL_DIR"

#Strip
strip "$INSTALL_DIR/usr/bin/bash"


echo "[+] Bash built and installed to $INSTALL_DIR/bin"

