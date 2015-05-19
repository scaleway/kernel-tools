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
GIT_URL=git://git.code.sf.net/p/aufs/aufs3-standalone

if [ "x$VERSION" = "x4" ]; then
    GIT=patches/aufs-aufs4-standalone
    GIT_URL=git://github.com/sfjro/aufs4-standalone.git
fi

# Clone AUFS repo
if [ ! -d $GIT ]; then
    which git || (apt-get update && apt-get install -y git)
    git clone -n $GIT_URL $GIT
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
grep -q CONFIG_AUFS_BDEV_LOOP .config || echo CONFIG_AUFS_BDEV_LOOP=y >> .config
grep -q CONFIG_AUFS_BRANCH_MAX_1023 .config || echo CONFIG_AUFS_BRANCH_MAX_1023=y >> .config
grep -q CONFIG_AUFS_FHSM .config || echo CONFIG_AUFS_FHSM=y >> .config
grep -q CONFIG_AUFS_FS .config || echo CONFIG_AUFS_FS=m >> .config
grep -q CONFIG_AUFS_RDU .config || echo CONFIG_AUFS_RDU=y >> .config
grep -q CONFIG_AUFS_SBILIST .config || echo CONFIG_AUFS_SBILIST=y >> .config
grep -q CONFIG_AUFS_XATTR .config || echo CONFIG_AUFS_XATTR=y >> .config

printf "Patched Kernel $KVER in $(cwd) with AUFS support!"
