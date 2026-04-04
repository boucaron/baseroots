TARGET = x86_64-linux-musl

# Where final toolchain goes
OUTPUT = $(PWD)/../../output/x86_64-musl


# Keep it small & static-friendly
COMMON_CONFIG += --disable-nls
COMMON_CONFIG += --enable-static

# Avoid multilib mess
GCC_CONFIG += --disable-multilib
