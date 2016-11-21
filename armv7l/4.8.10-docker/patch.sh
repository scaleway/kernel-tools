#!/usr/bin/env bash

KVER=4.8 /bin/bash -x patches/patch_aufs.bash

patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
git update-index --assume-unchanged arch/arm/mach-mvebu/coherency.c
