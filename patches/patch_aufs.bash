#!/bin/bash

###################################################
## Patch the Linux source tree with AUFS support ##
###################################################

# Target Kernel Version
VERSION=$(grep '^VERSION\s*=' Makefile | cut -d= -f2 | sed 's/\s//g')
PATCHLEVEL=$(grep '^PATCHLEVEL\s*=' Makefile | cut -d= -f2 | sed 's/\s//g')
KVER=$VERSION.$PATCHLEVEL
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
cat <<EOF  >> .config
CONFIG_AUFS_BDEV_LOOP=y
CONFIG_AUFS_BRANCH_MAX_1023=y
CONFIG_AUFS_FHSM=y
CONFIG_AUFS_FS=m
CONFIG_AUFS_RDU=y
CONFIG_AUFS_SBILIST=y
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
