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


# Usage: ./build_libc_core.sh <target>
TARGET_NAME="$1"

if [ -z "$TARGET_NAME" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi


BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_DIR="$BASE_DIR/initramfs/base"
LIB_DIR="$INSTALL_DIR/lib"

mkdir -p "$LIB_DIR"


# Find cross compiler sysroot
CROSS_CC="${TARGET_NAME}gcc"

if ! command -v "$CROSS_CC" >/dev/null 2>&1; then
    echo "Cross compiler not found: $CROSS_CC"
    exit 1
fi

CROSS_COMPILER_SYSROOT="$($CROSS_CC -print-sysroot)"

echo "Cross-compiler sysroot = $CROSS_COMPILER_SYSROOT"


# Install libc core shared libraries
echo "Installing libc core shared libraries"


# Runtime libraries only
RUNTIME_LIBS="
libc.so
libgcc_s.so.1
libstdc++.so.6
libstdc++.so.6.0.28
libatomic.so.1
libatomic.so.1.2.0
libssp.so.0
libssp.so.0.0.0
"


for lib in $RUNTIME_LIBS; do
    if [ -e "$CROSS_COMPILER_SYSROOT/lib/$lib" ]; then
        echo "  $lib"
        cp -a "$CROSS_COMPILER_SYSROOT/lib/$lib" "$LIB_DIR/"

    elif [ -e "$CROSS_COMPILER_SYSROOT/usr/lib/$lib" ]; then
        echo "  $lib"
        cp -a "$CROSS_COMPILER_SYSROOT/usr/lib/$lib" "$LIB_DIR/"

    else
        echo "  [skip] $lib not found"
    fi
done



# Create musl dynamic loader symlink
echo "Creating musl loader symlink"

MUSL_LOADER="$(basename "$(find "$CROSS_COMPILER_SYSROOT/lib" \
    -maxdepth 1 \
    -name 'ld-musl-*.so.1' \
    -type l | head -n 1)")"

if [ -n "$MUSL_LOADER" ]; then
    echo "  $MUSL_LOADER -> /lib/libc.so"
    ln -sf /lib/libc.so "$LIB_DIR/$MUSL_LOADER"
else
    echo "[!] musl loader not found"
fi



echo
echo "[+] Libc core installed in $LIB_DIR"
