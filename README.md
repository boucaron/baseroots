# BaseRoots

This is a small set of scripts to build a minimalist Linux base system.

The idea is simple:
you build a kernel, an initrd, and just enough tools to boot into a shell and do whatever you want.

You can use it as a kind of shim:
chroot into other distros, test things, experiment, break stuff.

---

## Why

25 years ago I was following freshmeat.net and building a lot of things from source.

It was a different time.
You were compiling everything, trying things, breaking your system, fixing it.
Not always efficient, but you learned a lot.

I think this spirit is still there, but a bit hidden now.

We have faster machines, better tools, cross-compilers, qemu…
so it should actually be easier to experiment like this today.

This project is just a small experiment I did during the Easter weekend 2026.

A tiny egg.

---

## What it does

You build what I call a *BaseRoot*:

* a Linux kernel
* an initrd (ramdisk)
* a minimal set of statically linked tools

That gives you a small system that boots and drops you into a shell.

From there, you do what you want.

---

## Example

An example recipe is:

`build_x86_64-musl.sh`

It builds a musl-based cross toolchain, then compiles toybox and bash,
and finally creates a minimal initrd.

At the end, you have everything except a kernel.
Add one, boot it in qemu, and you get a shell.

Most of the shell scripts are in:

`baseroot/toolchain/scripts/`

There are also a few additional ones for:

* dosfstools
* e2fsprogs
* util-linux (fdisk, etc.)

---

## Current state

For now:

* x86_64 only
* musl libc
* gcc
* toybox
* static linking

It’s very basic.

---

## Philosophy (if any)

There is no real opinion here.

You can swap everything:

* libc (musl, glibc, …)
* compiler (gcc, clang, …)
* tools (toybox, busybox, GNU, BSD…)
* init (or no init)

It’s just a set of recipes.

Take it, change it, experiment.

---

## Future

I want to try different combinations:
different libc, different compilers, different userlands.

Also cross-compiling for random hardware and testing in qemu.

---

## License

This project is licensed under the 0BSD license.

You can use it as you like:
copy it, modify it, redistribute it, use it in other projects, with or without attribution.

Basically: do whatever you want.


