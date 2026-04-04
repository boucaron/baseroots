#!/bin/sh
set -e

TARGET_NAME="$1"
MODE="$2"

if [ -z "$TARGET_NAME" ]; then
    echo "Usage: $0 <target> [clean|distclean]"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$BASE_DIR/build/$TARGET_NAME"
OUTPUT_DIR="$BASE_DIR/output/$TARGET_NAME"

echo "[*] Cleaning target: $TARGET_NAME"

if [ -d "$BUILD_DIR" ]; then
    echo "[-] Removing build directory"
    rm -rf "$BUILD_DIR"
fi
 
if [ "$MODE" = "distclean" ]; then
    if [ -d "$OUTPUT_DIR" ]; then
        echo "[-] Removing output directory"
        rm -rf "$OUTPUT_DIR"
    fi
fi

echo "[+] Clean complete"
