![BaseRoots Logo](assets/image_small.jpg)

# BaseRoots

**BaseRoots — Tiny, Immutable Linux Environment for Recovery, Testing, and Reproducible Boot**

BaseRoots is a minimal, reproducible Linux bootstrap environment designed to
reliably boot, inspect, and recover Linux systems.

It builds a small, mostly statically linked initrd that provides a clean,
deterministic runtime independent of the host system.

---

## Why

Recovering or inspecting Linux systems is often inconsistent:

- rescue environments differ between distributions  
- tools and behavior vary across systems  
- debugging depends on the state of the host OS  

BaseRoots provides a clean, reproducible environment that behaves the same
every time, regardless of the system being inspected.

---

## What it does

BaseRoots builds what we call a *BaseRoot*:

- a Linux kernel (provided separately)  
- an initrd (ramdisk)  
- a minimal set of mostly statically linked tools  

The result is a small system that boots into a shell in a controlled environment.

From there, you can:

- inspect and mount disks  
- recover broken systems  
- chroot into existing installations  
- debug system failures  
- experiment with different userlands  

---

## Example use case

A server fails to boot after an update.

With BaseRoots:

1. Boot the system using a BaseRoots initrd (locally or via PXE)
2. Enter a clean, known environment
3. Detect and mount disks safely
4. Inspect logs, repair filesystems, or recover data

The environment is always identical, regardless of the system state.

---

## Example build

An example recipe is:

`build_x86_64-musl.sh`

It:

- builds a musl-based cross toolchain  
- compiles toybox and bash  
- creates a minimal initrd  

At the end, you have everything except a kernel.

Add a kernel, boot it, and you get a shell.

Most scripts are located in:

`baseroot/toolchain/scripts/`

---

## Included tooling (example)

BaseRoots can include a minimal but practical recovery toolkit:

**Filesystems**
- e2fsprogs  
- xfsprogs  
- btrfs-progs  
- dosfstools  

**Disk utilities**
- util-linux (fdisk, mount, blkid, etc.)  

**System / kernel**
- kmod  

**Networking**
- iproute2  

This is enough to build a small, usable recovery environment.

---

## What this is not

BaseRoots is not a full Linux distribution.

It does not aim to replace existing systems, but to provide a minimal,
controlled environment to interact with them.

---

## Design principles

- minimal and focused  
- reproducible runtime  
- mostly statically linked  
- cross-compiled  
- independent of host system  
- customizable at build time  

---

## Background

25 years ago, building systems from source and experimenting freely was common.

Today we have faster machines, better tools, cross-compilers, and virtualization.
It should be easier than ever to explore systems in a controlled way.

BaseRoots is a small experiment in that direction.

---

## Current state

- architecture: x86_64  
- libc: musl  
- toolchain: gcc  
- tools: toybox + additional utilities  
- linking: mostly static  

Status: experimental but functional.

---

## Future

- PXE / network boot support  
- extended recovery tooling (LVM, encryption, RAID)  
- multiple build profiles (recovery, forensics, testing)  
- additional architectures  
- more userland combinations  

---

## License

This project is licensed under the 0BSD license.

You can use it as you like:
copy it, modify it, redistribute it, use it in other projects, with or without attribution.

Basically: do whatever you want.
