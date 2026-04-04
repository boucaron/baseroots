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

