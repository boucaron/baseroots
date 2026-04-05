#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import common variables/functions from same directory as this script
COMMON_SH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "[!] Missing common.sh at $COMMON_SH"
    exit 1
fi

. "$COMMON_SH"

# Usage: ./build_disk_util-linux.sh <cross-compiler-prefix>
# Example: ./build_disk_util-linux.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/util-linux"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    git clone --depth=1 https://github.com/util-linux/util-linux.git "$SRC_DIR"
fi

cd "$SRC_DIR"
make distclean || true

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"

if [ ! -f "configure" ]; then
   ./autogen.sh
fi

./configure \
  --host="${CROSS_PREFIX%-}" \
  --prefix=/usr \
  --disable-shared \
  --enable-static \
  --enable-libblkid \
  --enable-libuuid \
  --enable-libmount \
  --enable-static-programs=fdisk,sfdisk,losetup,mount,umount \
  --disable-nls \
  --without-python \
  --without-systemd \
  --without-udev \
  --without-selinux \
  --without-tinfo \
  --without-readline \
  --without-ncurses \
  CC="${CROSS_PREFIX}cc -static" \
  CFLAGS="-O2" \
  LDFLAGS="-static -Wl,--gc-sections"

make -j"$JOBS_NUM"

# Install everything (for now, since you want to measure)
# make DESTDIR="$INSTALL_DIR" install
cp -f fdisk.static $INSTALL_DIR/sbin/fdisk
cp -f sfdisk.static $INSTALL_DIR/sbin/sfdisk
cp -f umount.static $INSTALL_DIR/bin/umount
cp -f losetup.static $INSTALL_DIR/bin/losetup
cp -f mount.static $INSTALL_DIR/bin/mount

# Strip all binaries
find "$INSTALL_DIR" -type f -executable -exec $STRIP {} \; || true

echo "[+] Disk/util-linux (fdisk + disk tools) installed"

