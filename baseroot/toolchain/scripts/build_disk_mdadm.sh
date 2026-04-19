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

# Usage: ./build_disk_mdadm.sh <cross-compiler-prefix>
# Example: ./build_disk_mdadm.sh x86_64-linux-musl-

CROSS_PREFIX="$1"
[ -z "$CROSS_PREFIX" ] && { echo "Usage: $0 <cross-prefix>"; exit 1; }

BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$BASE_DIR/src/mdadm-4.6"
INSTALL_DIR="$BASE_DIR/initramfs/base"

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/sbin"

# Fetch source
if [ ! -d "$SRC_DIR" ]; then
    wget https://git.kernel.org/pub/scm/utils/mdadm/mdadm.git/snapshot/mdadm-4.6.tar.gz
    cp -f mdadm-4.6.tar.gz "$BASE_DIR/src/"
    cd "$BASE_DIR/src/"
    tar xfz mdadm-4.6.tar.gz
    cd -
    cd "$SRC_DIR"
    sed -i 's/^# LDFLAGS += -static/LDFLAGS += -static/' Makefile
    sed -i 's/^# STRIP = -s/STRIP = -s/' Makefile
    sed -i '/^CWFLAGS/ s/-fPIE//g' Makefile
    cd -
fi

cd "$SRC_DIR"
make clean || true

CC="${CROSS_PREFIX}cc -static"
STRIP="${CROSS_PREFIX}strip"

CFLAGS="-O2"
LDFLAGS="-Wl,--gc-sections"

# Build
CC="${CROSS_PREFIX}cc -static  -fno-pie -no-pie" \
CFLAGS="-O2" \
CXFLAGS="-DNO_LIBUDEV" \
LDFLAGS="-static -no-pie -Wl,-z,now,-z,noexecstack" \
make V=1 -j"$JOBS_NUM"

# Install

make V=1 DESTDIR="$INSTALL_DIR" install-bin

# Strip all binaries
# find "$INSTALL_DIR" -type f -executable -exec $STRIP {} \; || true

echo "[+] Disk mdadm installed"

