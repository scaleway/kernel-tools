#!/bin/bash

set -e

###################################################
## Patch the Linux source tree with AUFS support ##
###################################################

# Target Kernel Version
VERSION=$(grep '^VERSION\s*=' Makefile | cut -d= -f2 | sed 's/\s//g')
PATCHLEVEL=$(grep '^PATCHLEVEL\s*=' Makefile | cut -d= -f2 | sed 's/\s//g')
KVER=$VERSION.$PATCHLEVEL
# Temporary Location
#TMPGIT=`mktemp -d`
GIT=patches/aufs-aufs3-standalone

# Clone AUFS repo
if [ ! -d $GIT ]; then
    which git || (apt-get update && apt-get install -y git)
    git clone -n git://git.code.sf.net/p/aufs/aufs3-standalone $GIT
fi

# Checkout AUFS branch
pushd $GIT
git checkout origin/aufs$KVER
popd

# Copy in files
cp -r $GIT/{Documentation,fs} ./
cp $GIT/include/uapi/linux/aufs_type.h ./include/uapi/linux/aufs_type.h

# Apply patches
cat $GIT/aufs3-{base,kbuild,loopback,mmap,standalone}.patch | patch -p1

# Clean Up
#rm -rf $GIT

# Enable module
cat <<EOF  >> .config
CONFIG_AUFS_BDEV_LOOP=y
CONFIG_AUFS_BRANCH_MAX_1023=y
CONFIG_AUFS_FHSM=y
CONFIG_AUFS_FS=m
CONFIG_AUFS_RDU=y
CONFIG_AUFS_SBILIST=y
CONFIG_AUFS_XATTR=y
# CONFIG_AUFS_BRANCH_MAX_127 is not set
# CONFIG_AUFS_BRANCH_MAX_32767 is not set
# CONFIG_AUFS_BRANCH_MAX_511 is not set
# CONFIG_AUFS_BR_FUSE is not set
# CONFIG_AUFS_BR_HFSPLUS is not set
# CONFIG_AUFS_BR_RAMFS is not set
# CONFIG_AUFS_DEBUG is not set
# CONFIG_AUFS_EXPORT is not set
# CONFIG_AUFS_HNOTIFY is not set
# CONFIG_AUFS_SHWH is not set
EOF

printf "Patched Kernel $KVER in $(cwd) with AUFS support!"
