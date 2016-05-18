#!/usr/bin/env bash

# arm io coherency
patch -p1 < patches/patch-enable-IO-coherency-4.0.patch
git update-index --assume-unchanged arch/arm/mach-mvebu/coherency.c

# android from Joel Isaacson joel@ascender.com
patch -p1 < patches/android/0001-These-patches-will-allow-the-Android-binder-driver-i.patch
patch -p1 < patches/android/0002-This-patch-is-not-really-needed-for-Android-Lollipop.patch
