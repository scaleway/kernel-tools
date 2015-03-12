#!/usr/bin/env bash

/bin/bash -x patches/patch_aufs.bash
patch -p1 < patches/0001-enable-hardware-I-O-coherency.patch
patch -p1 < patches/patch-cpuidle-3.19-std.patch
