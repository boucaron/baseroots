#!/bin/sh


TARGET_ARCH_LIBC=x86_64-musl
TARGET_CROSS_ARCH_LIBC=x86_64-linux-musl-

# Build cross compiler with libc
./baseroot/toolchain/scripts/build.sh $TARGET_ARCH_LIBC

# Build toybox
# Build bash
./baseroot/toolchain/scripts/build_toybox.sh $TARGET_CROSS_ARCH_LIBC
./baseroot/toolchain/scripts/build_bash.sh $TARGET_CROSS_ARCH_LIBC

# Build initrd
cd baseroot/toolchain/initramfs/base
find . | cpio -H newc -o > ../base.cpio
cd -

echo "[+] Done: Initrd ready"
