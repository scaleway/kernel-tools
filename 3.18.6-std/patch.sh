#!/usr/bin/env bash

patch -p1 < patches/0001-enable-hardware-I-O-coherency.patch
patch -p1 < patches/patch-cpuidle.patch
