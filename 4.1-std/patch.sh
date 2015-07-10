#!/bin/sh

patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
git update-index --assume-unchanged arch/arm/mach-mvebu/coherency.c
#patch -p1 < patches/patch-cpuidle-4.0.patch

# sgmii mvneta
patch -p1 < patches/0001-of-mdio-add-new-dt-property-link.patch
patch -p1 < patches/0002-mvneta-use-inband-status-only-when-link-auto.patch
