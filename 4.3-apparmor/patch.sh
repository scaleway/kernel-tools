#!/bin/sh

patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
git update-index --assume-unchanged arch/arm/mach-mvebu/coherency.c
#patch -p1 < patches/patch-cpuidle-4.0.patch

# sgmii mvneta
#patch -p1 < patches/patch-inband-status_1.patch
#patch -p1 < patches/patch-inband-status_2.patch
#patch -p1 < patches/patch-inband-status_3.patch
#patch -p1 < patches/patch-inband-status_4.patch
#patch -p1 < patches/patch-mvneta-DMA-buffer-unmapping.patch
