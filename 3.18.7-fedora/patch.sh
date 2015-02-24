#!/usr/bin/env bash

patch -p1 < patches/patch-cpuidle-3.17-std.patch
patch -p1 < patches/0001-ntp-Fixup-adjtimex-freq-validation-on-32bit-systems.patch
