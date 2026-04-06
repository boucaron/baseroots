# BaseRoots

This is a small set of scripts to setup and to build a minimalist rescue system and eventually to build a minimalist linux distro for my needs.
The goal is to use it as a shim where you chroot to multiple linux distros or run whatever experiment you want to do.
There is no opinion, nothing, you can change it, experiment with it, it is freedom.
25 years ago I was following freshmeat.net and building a lot of stuff from source code, to learn new stuff, to experiment, it was a kind of golden age.
I strongly think the spririt is there, but we need to energize it.
Also we have faster hardware and new tools to make it simpler, easier, faster so I think it is a cool stuff to do.
I experimented with this basic stuff during the 2026 Easter weeked, here is a tiny egg.

What is it:
Basically, you have a cross compiler and its libc: this is your fundation that is used to compile a Linux kernel, and more important the few base tools that are mandatory to boot a Linux kernel and to have a small usable system to make things, using what is called a initrd, which is a small ramdisk.
The main idea is you have a small set of scripts where you can build what I call a BaseRoot:
a minimalist kind of rescue system where you have a kernel, an initrd containing the set of tools you need, you want, your call: tailored to you need,
and play with it.


Current state:
For the moment, I only worked with x86_64 and I choosen musl for the libc.
All built tools are statically linked, so you can peak and choose whatever you need.
It is just a set of recipes, try it, experiment it, tune it, change it, innovate, have fun and share it.

Future ?
I am unopiniated: I have a musl libc, and I want also a glibc and any other libc variants.
I don't care about the compiler, I use gcc and I want also a llvm/clang or any other compiler.
I used toybox for the main core binaries, I want also to make a variant with busybox or various versions using GNU 'classic' tools or anything else, or a BSD userland, or something else.
I did not put any init just a small shell script calling sh, I want also to put various variants of init and so on.
So you feel me, it is about experiments and try to make various recipes to experiment, to try new stuff.
It could also be you crosscompile for whatever piece of hardware you have like, you launch a qemu directly on it and test.





Follows my notes, it is not a readme, not up to date in general, so take it with a grain of salt.

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
