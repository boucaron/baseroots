# BaseRoots Quick Notes

> This is my personal notes — not a polished README.
> Things may be outdated, so take it with a grain of salt.

---

## Build cross compiler

```bash
./baseroot/toolchain/scripts/build.sh x86_64-musl
```

* You can edit the number of parallel jobs inside `common.sh` if needed.

### Cleanup

```bash
./baseroot/toolchain/scripts/clean.sh x86_64-musl
./baseroot/toolchain/scripts/clean.sh x86_64-musl distclean
```

### Quick check

```bash
ls baseroot/toolchain/output/x86_64-musl/bin
```

Test the compiler:

```bash
export PATH=$PWD/baseroot/toolchain/output/x86_64-musl/bin:$PATH

echo '#include <stdio.h>
int main(){ puts("Hello BaseRoots"); }' > hello.c

x86_64-linux-musl-gcc -static hello.c -o hello
file hello
./hello
```

Expected output:

```
hello: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, not stripped
Hello BaseRoots
```

---

## Build kernel headers

Musl cross compilation is using a relatively 'old' linux kernel and its headers are not really compatible with recent version of filesystem utils.
In general you want to take a more recent kernel.


```bash
./baseroot/toolchain/scripts/build_kernel_headers.sh x86_64-linux-musl-
```


---

## Install libc core shared libraries

Even if most of the tools are statically compiled, a few tools needs a shared libc (kmod for instance)
```bash
./baseroot/toolchain/scripts/build_libc_core.sh x86_64-linux-musl-
```



---

## Build toybox

```bash
./baseroot/toolchain/scripts/build_toybox.sh x86_64-linux-musl-
```

Check:

```bash
ls baseroot/toolchain/initramfs/base/bin/
```

---

## Build initramfs

```bash
cd baseroot/toolchain/initramfs/base
find . | cpio -H newc -o > ../base.cpio
cd ../..
```

---

## Build bash

```bash
./baseroot/toolchain/scripts/build_bash.sh x86_64-linux-musl-
```

Check:

```bash
ls baseroot/toolchain/initramfs/base/usr/bin/bash
```

---

## Build kernel

```bash
cd kernel/src/mykernel-src
make mrproper
make defconfig
# optionally edit config
make -j8 bzImage
```

---

## Launch QEMU for testing

```bash
qemu-system-x86_64 \
  -kernel ./arch/x86_64/boot/bzImage \
  -initrd ../../../toolchain/initramfs/base.cpio \
  -nographic \
  -append "console=ttyS0 rdinit=/sbin/init raid=noautodetect"
```

---
