#!/bin/bash

wget https://raw.githubusercontent.com/online-labs/kernel-config/master/patches/0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch
patch -p1 < 0001-net-mvneta-fix-TX-coalesce-interrupt-mode.patch
