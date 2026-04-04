#!/bin/sh
set -e

TARGET_NAME="$1"

if [ -z "$TARGET_NAME" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
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

# Copy source (clean build per target)
cp -r "$SRC_DIR"/* .

# Inject config
cp "$TARGET_DIR/config.mak" config.mak

echo "[*] Building toolchain: $TARGET_NAME"
make
make install

echo "[+] Done: $TARGET_NAME"
