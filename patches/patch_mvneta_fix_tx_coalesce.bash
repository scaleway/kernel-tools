#!/bin/bash

set -e

mkdir -p patches
if [ ! -f patches/0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch ]; then
    wget https://raw.githubusercontent.com/online-labs/kernel-config/master/patches/0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch -O patches/0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch
fi
patch -p1 < patches/0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch
