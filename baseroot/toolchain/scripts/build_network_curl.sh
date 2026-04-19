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
# Usage: ./build_network_curl.sh <cross-compiler-prefix>
# Example: ./build_network_curl.sh x86_64-linux-musl-

CROSS_PREFIX="$1"

if [ -z "$CROSS_PREFIX" ]; then
    echo "Usage: $0 <cross-compiler-prefix>"
    exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$BASE_DIR/src/curl-8.19.0"
BUILD_DIR="$BASE_DIR/build/curl"
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
    wget  https://curl.se/download/curl-8.19.0.tar.gz
    cp -f curl-8.19.0.tar.gz "$BASE_DIR/src" 
    cd "$BASE_DIR/src"
    tar xfz curl-8.19.0.tar.gz
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
   --without-libpsl \
   --enable-static=curl \
   --disable-shared \
   CC="${CROSS_PREFIX}cc -static" \
   CFLAGS="-O2" \
   LDFLAGS="-static -Wl,--gc-sections"


  
# Build main binaries 
make V=1 -j"$JOBS_NUM"

rm src/curl
cd src
"${CROSS_PREFIX%-}"-cc -static -O2 -Werror-implicit-function-declaration -Wno-system-headers -Wl,--gc-sections -o curl curl-config2setopts.o curl-slist_wc.o curl-terminal.o curl-tool_cb_dbg.o curl-tool_cb_hdr.o curl-tool_cb_prg.o curl-tool_cb_rea.o curl-tool_cb_see.o curl-tool_cb_soc.o curl-tool_cb_wrt.o curl-tool_cfgable.o curl-tool_dirhie.o curl-tool_doswin.o curl-tool_easysrc.o curl-tool_filetime.o curl-tool_findfile.o curl-tool_formparse.o curl-tool_getparam.o curl-tool_getpass.o curl-tool_help.o curl-tool_helpers.o curl-tool_ipfs.o curl-tool_libinfo.o curl-tool_listhelp.o curl-tool_main.o curl-tool_msgs.o curl-tool_operate.o curl-tool_operhlp.o curl-tool_paramhlp.o curl-tool_parsecfg.o curl-tool_progress.o curl-tool_setopt.o curl-tool_ssls.o curl-tool_stderr.o curl-tool_urlglob.o curl-tool_util.o curl-tool_vms.o curl-tool_writeout.o curl-tool_writeout_json.o curl-tool_xattr.o curl-var.o toolx/curl-tool_time.o curl-tool_hugehelp.o curl-tool_ca_embed.o  ../lib/.libs/libcurl.a -lssl -lcrypto -lzstd -lz
"$STRIP" curl 
cd -

# Install binaries
#make V=1  DESTDIR="$INSTALL_DIR"  -n install
cp -f src/curl $INSTALL_DIR/usr/bin

echo "[+] Network/curl built and installed to $INSTALL_DIR."

