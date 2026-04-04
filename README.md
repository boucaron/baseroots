# BaseRoot

This is a small tool to setup and to build a minimalist linux distro.
The goal is to use it as a shim where you chroot to multiple linux distros.
There is no opinion, nothing, you can change it, experiment with it, it is freedom.


Usage to build cross compiler:
./baseroot/toolchain/scripts/build.sh x86_64-musl
Usage to cleanup cross compiler:
./baseroot/toolchain/scripts/clean.sh x86_64-musl
./baseroot/toolchain/scripts/clean.sh x86_64-musl distclean

