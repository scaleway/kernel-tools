#!/usr/bin/env bash

patch -p1 < patches/aufs-aufs3-debian-3.2/aufs3-add.patch
patch -p1 < patches/aufs-aufs3-debian-3.2/aufs3-base.patch
patch -p1 < patches/aufs-aufs3-debian-3.2/aufs3-fix-export-__devcgroup_inode_permission.patch
patch -p1 < patches/aufs-aufs3-debian-3.2/aufs3-kbuild.patch
patch -p1 < patches/aufs-aufs3-debian-3.2/aufs3-standalone.patch
patch -p1 < patches/aufs-aufs3-debian-3.2/mark-as-staging.patch
