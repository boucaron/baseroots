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

TARGET_NAME="$1"

if [ -z "$TARGET_NAME" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

# Determine absolute BASE_DIR robustly
SCRIPT_PATH="$(realpath "$0")"
BASE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

KERNEL_VERSION=linux-6.19.11
KERNEL_SRC_BASE="$BASE_DIR/../kernel/src/$KERNEL_VERSION"

if [ ! -d "$KERNEL_SRC_BASE" ]; then
    echo "Kernel source tree not found for: $KERNEL_SRC_BASE"
    exit 1
fi
echo "Found Kernel headers: $KERNEL_SRC_BASE"

KERNEL_HEADERS_TMP="$KERNEL_SRC_BASE/../tmp/$KERNEL_VERSION"
if [ ! -d "KERNEL_HEADERS_TMP" ]; then
    echo "Cleanup previous tmp directory"
    rm -rf KERNEL_HEADERS_TMP
fi
mkdir -p "$KERNEL_HEADERS_TMP"


# Find cross compiler sysroot
CROSS_CC="${TARGET_NAME}musl-gcc"

if ! command -v "$CROSS_CC" >/dev/null 2>&1; then
    echo "Cross compiler not found: $CROSS_CC"
    exit 1
fi

CROSS_COMPILER_SYSROOT="$($CROSS_CC -print-sysroot)"

echo "Cross-compiler sysroot = $CROSS_COMPILER_SYSROOT"


# Generate Linux userspace headers
echo "Generating Linux UAPI headers..."

make -C "$KERNEL_SRC_BASE" \
    ARCH=x86_64 \
    headers_install \
    INSTALL_HDR_PATH="$KERNEL_HEADERS_TMP"


NEW_HEADERS="$KERNEL_HEADERS_TMP/include"

if [ ! -d "$NEW_HEADERS/linux" ]; then
    echo "Generated headers not found in $NEW_HEADERS"
    exit 1
fi


# Backup existing headers
SYSROOT_INCLUDE="$CROSS_COMPILER_SYSROOT/usr/include"

BACKUP="$SYSROOT_INCLUDE/kernel-headers-backup-$(date +%Y%m%d-%H%M%S)"

echo "Backing up existing kernel headers to:"
echo "  $BACKUP"

mkdir -p "$BACKUP"

for d in linux asm asm-generic; do
    if [ -e "$SYSROOT_INCLUDE/$d" ]; then
        mv "$SYSROOT_INCLUDE/$d" "$BACKUP/"
    fi
done


# Install new headers
echo "Installing Linux UAPI headers..."

cp -a "$NEW_HEADERS/linux" \
      "$SYSROOT_INCLUDE/"

cp -a "$NEW_HEADERS/asm-generic" \
      "$SYSROOT_INCLUDE/"

cp -a "$NEW_HEADERS/asm" \
      "$SYSROOT_INCLUDE/"


# Verify
echo "Checking installed kernel headers..."

grep LINUX_VERSION "$SYSROOT_INCLUDE/linux/version.h" || true

if grep -q STATMOUNT_MNT_POINT "$SYSROOT_INCLUDE/linux/mount.h"; then
    echo "[OK] statmount API available"
else
    echo "[!] statmount API not found"
fi

echo "Done."



