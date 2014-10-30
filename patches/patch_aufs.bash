#!/bin/bash

###################################################
## Patch the Linux source tree with AUFS support ##
###################################################

# Target Kernel Version
KVER=3.17
# Temporary Location
TMPGIT=`mktemp -d`

# Clone AUFS repo
git clone -n git://git.code.sf.net/p/aufs/aufs3-standalone $TMPGIT/aufs-aufs3-standalone

# Checkout AUFS branch
pushd $TMPGIT/aufs-aufs3-standalone
git checkout origin/aufs$KVER
popd

# Copy in files
cp -r $TMPGIT/aufs-aufs3-standalone/{Documentation,fs} ./
cp $TMPGIT/aufs-aufs3-standalone/include/uapi/linux/aufs_type.h ./include/uapi/linux/aufs_type.h

# Apply patches
cat $TMPGIT/aufs-aufs3-standalone/aufs3-{base,kbuild,loopback,mmap,standalone}.patch | patch -p1

# Clean Up
rm -rf $TMPGIT/aufs-aufs3-standalone

# Enable module
echo "CONFIG_AUFS_FS=m" >> .config

printf "Patched Kernel $KVER in $(cwd) with AUFS support!"
