#!/usr/bin/env bash

patch -p1 < patches/patch-disable-IO-coherency-3.17-std.patch
patch -p1 < patches/patch-cpuidle-3.17-std.patch
