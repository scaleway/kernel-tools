#!/usr/bin/env bash

/bin/bash -x patches/patch_aufs.bash
patch -p1 < patches/patch-cpuidle-3.17-std.patch
