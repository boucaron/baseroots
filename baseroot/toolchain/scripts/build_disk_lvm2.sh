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

# Usage: ./build_disk_lvm2.sh <cross-compiler-prefix>
# Example: ./build_disk_lvm2.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/LVM2.2.03.39"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    wget https://sourceware.org/pub/lvm2/releases/LVM2.2.03.39.tgz
    cp -f LVM2.2.03.39.tgz "$BASE_DIR/src/"
    cd "$BASE_DIR/src/"
    tar xfz LVM2.2.03.39.tgz
    cd -
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

# Patching
FILE="tools/lvmcmdline.c"

sed -i \
  -e 's/!(stdin *= *fopen(_PATH_DEVNULL, *"r"))/!freopen(_PATH_DEVNULL, "r", stdin))/g' \
  -e 's/!(stdout *= *fopen(_PATH_DEVNULL, *"w"))/!freopen(_PATH_DEVNULL, "w", stdout))/g' \
  -e 's/!(stderr *= *fopen(_PATH_DEVNULL, *"w"))/!freopen(_PATH_DEVNULL, "w", stderr))/g' \
  "$FILE"


./configure \
  --host="${CROSS_PREFIX%-}" \
  --prefix=/usr \
  --disable-shared \
  --enable-static \
  --disable-nls \
  --disable-readline \
  --without-systemd \
  --disable-dbus-service \
  CC="${CROSS_PREFIX}cc -static" \
  CFLAGS="-O2" \
  LDFLAGS="-static -Wl,--gc-sections"

make V=1 -j"$JOBS_NUM"

# DON'T Install everything...

# Strip all binaries
find "$INSTALL_DIR" -type f -executable -exec $STRIP {} \; || true

echo "[+] Disk/lvm2 installed"

