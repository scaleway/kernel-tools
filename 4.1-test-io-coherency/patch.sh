#!/bin/sh

#patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
#git update-index --assume-unchanged arch/arm/mach-mvebu/coherency.c
#patch -p1 < patches/patch-cpuidle-4.0.patch
patch -p1 < patches/patch-mvneta-fix-init-nego.patch
