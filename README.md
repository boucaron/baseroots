# BaseRoot

This is a small tool to setup and to build a minimalist linux distro.
The goal is to use it as a shim where you chroot to multiple linux distros.
There is no opinion, nothing, you can change it, experiment with it, it is freedom.


Usage to build cross compiler:
./baseroot/toolchain/scripts/build.sh x86_64-musl

Have a look and edit the number of parallel jobs in the build.sh

Usage to cleanup cross compiler:
./baseroot/toolchain/scripts/clean.sh x86_64-musl
./baseroot/toolchain/scripts/clean.sh x86_64-musl distclean


Once cross compiler has finished quick check that it is working:
ls baseroot/toolchain/output/x86_64-musl/bin

export PATH=$PWD/baseroot/toolchain/output/x86_64-musl/bin:$PATH

echo '#include <stdio.h>
int main(){ puts("Hello BaseRoots"); }' > hello.c

x86_64-linux-musl-gcc -static hello.c -o hello
file hello

hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, not stripped

./hello 
Hello BaseRoots

Usage to build toybox:
./baseroot/toolchain/scripts/build_toybox.sh x86_64-linux-musl-

Check: ls baseroot/toolchain/initramfs/base/bin/

Build initramfs:
cd initramfs/base
find . | cpio -H newc -o > ../base.cpio
cd ../..



Usage to build bash:
./baseroot/toolchain/scripts/build_bash.sh  x86_64-linux-musl-

Check: ls baseroot/toolchain/initramfs/base/usr/bin/bash

Build kernel:
cd kernel/src/mykernel-src
make mrproper
make defconfig
# optionally edit config
make -j8 bzImage


Launch qemu to test:
qemu-system-x86_64 -kernel ./arch/x86_64/boot/bzImage  -initrd ../../../toolchain/initramfs/base.cpio   -nographic -append "console=ttyS0 rdinit=/sbin/init raid=noautodetect"
