#!/bin/sh

patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
#patch -p1 < patches/patch-cve-2016-0728.patch

#patch -p1 < patches/patch-cpuidle-4.0.patch
#patch -p1 < patches/0001-ntp-Fixup-adjtimex-freq-validation-on-32bit-systems.patch

# sgmii mvneta
#patch -p1 < patches/patch-inband-status_1.patch
#patch -p1 < patches/patch-inband-status_2.patch
#patch -p1 < patches/patch-inband-status_3.patch
#patch -p1 < patches/patch-inband-status_4.patch
#patch -p1 < patches/patch-mvneta-DMA-buffer-unmapping.patch
