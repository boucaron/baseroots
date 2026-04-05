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

SRC_DIR="$BASE_DIR/src/musl-cross-make"
TARGET_DIR="$BASE_DIR/targets/$TARGET_NAME"
BUILD_DIR="$BASE_DIR/build/$TARGET_NAME"

if [ ! -d "$SRC_DIR" ]; then
    echo "musl-cross-make not found in src/"
    exit 1
fi

if [ ! -f "$TARGET_DIR/config.mak" ]; then
    echo "Missing config: $TARGET_DIR/config.mak"
    exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Copy source, including hidden files
cp -r "$SRC_DIR"/. .

# Inject config
cp "$TARGET_DIR/config.mak" config.mak

echo "[*] Building toolchain: $TARGET_NAME"


echo "[*] Building toolchain: $TARGET_NAME with $JOBS_NUM jobs"
make -j"$JOBS_NUM"
make install

echo "[+] Done: $TARGET_NAME"
