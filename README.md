Kernel Config [![Build Status](https://travis-ci.org/online-labs/kernel-config.svg?branch=master)](https://travis-ci.org/online-labs/kernel-config)
=============

https://community.cloud.online.net/t/official-linux-kernel-new-modules-optimizations-hacks/226

The kernel is built with the official mainline kernel, here are the .config files used.

Modifications
-------------

We added kernel module to simulate some virtualization features:
- serial console activation
- remote soft reset trigger

---

Kernels
=======

Name              | Maintainer      | Sources | Target | Links
------------------|-----------------|---------|--------|-------
3.17.8            | Linux community | Open    | C1     | [Sources](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/?id=v3.17.8/)
3.18.9            | Linux community | Open    | C1     | [Sources](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/?id=v3.18.9/)
3.19.1            | Linux community | Open    | C1     | [Sources](https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/?id=v3.19.1/)
4.0-rc2           | Linux community | Open    | C1     | [Sources](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/?id=v4.0-rc2)
3.2.34-std        | Marvell         | Closed  | C1     | n/a

---

Build a custom kernel using Docker
==================================

Run a `make menuconfig` for `3-18-std/.config`

    make menuconfig KERNEL=3.18-std

Build a kernel with `3.17-std/.config` file

    make build KERNEL=3.17-std

Create a new `3.10-new/.config` file from scratch for kernel `3.10`

    make defconfig KERNEL=3.10-new

Run a shell in the container for easy debugging and run custom commands

    make shell KERNEL=3.17-std

Test a kernel with QEMU
=======================

You should use a config file made for `versatile`.

Build a `3.18` kernel for `versatile`:

    make build KERNEL=3.18-defconfig_versatile

Run the kernel in qemu

    make qemu KERNEL=3.18-defconfig_versatile

---

Build a custom kernel from scratch (without Docker)
===================================================

Prerequisites:
--------------

- An arm(hf) compiler:
  - a cross-compiler on non-armhf host, ie `gcc-arm-linux-gnueabihf`
  - a standard compiler from an armhf host (you can build a kernel from your C1)
- Theses packages: git, wget, make


Steps:
------

- Configure environment
  ```bash
export VERSION=3.17
export ARCH=arm
export ARTIFACTS=artifacts
```

- Download archive via web
  ```bash
wget https://kernel.org/pub/linux/kernel/v3.x/linux-$VERSION.tar.xz && tar xf linux-$VERSION.tar.xz
  ```
  or via git
  ```bash
git clone -b v$VERSION --single-branch git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-$VERSION
```

- Generate a base `.config` file by building it
  ```
make ARCH=arm mvebu_v7_defconfig
```
  or by fetching our one
  ```
wget -O .config https://raw.githubusercontent.com/online-labs/kernel-config/master/.config-$VERSION-std
```

- Tune the .config
  ```bash
make ARCH=arm menuconfig
# ... configure using console interface
```

- Building kernel and modules
  ```bash
make -j $(echo `nproc` ' * 2' | bc) uImage modules LOADADDR=0x8000
```

- Export the artifacts (kernel, header, modules) to `$ARTIFACTS` directory
  ```bash
mkdir -p $ARTIFACTS
cp arch/arm/boot/uImage $ARTIFACTS/
cp System.map $ARTIFACTS/
cp .config $ARTIFACTS/
make headers_install INSTALL_HDR_PATH=$ARTIFACTS/ > /dev/null
find $ARTIFACTS/include -name ".install" -or -name "..install.cmd" -delete
make modules_install INSTALL_MOD_PATH=$ARTIFACTS/ > /dev/null
rm -rf $ARTIFACTS/modules && \
   mv $ARTIFACTS/lib/modules $ARTIFACTS && \
   rmdir $ARTIFACTS/lib && \
   rm $ARTIFACTS/modules/*/source $ARTIFACTS/modules/*/build
```

Minimal configuration for C1 servers
------------------------------------

```gherkin
- Networking support
  - Networking options
    - 802.1Q/802.1ad VLAN Support -> **YES**
    - Packet socket -> **YES**
    - Unix domain sockets -> **YES**
- Device Drivers
  - Network device support
    - PHY Device support and infrastructure
      - Driver for MDIO Bus/PHY emulation with fixed speed/link PHYs -> **YES**
  - Block devices
    - Network block device support -> **YES**
- Kernel hacking
  - Kernel low-level debugging functions -> **YES**
  - Early prink -> **YES**
- File systems
  - The Extended 4 (ext4) filesystem -> **YES**
```

Releases
========

2014-10-15 - 3.17.0-85
----------------------

- used .config: https://github.com/online-labs/kernel-config/blob/3.17.0-85/.config-3.17-std
- community discuttion: https://community.cloud.online.net/t/official-linux-kernel-new-modules-optimizations-hacks/226/6?u=manfred
- kernel commit: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tag/?id=v3.17

Licensing
=========

© 2014-2015 Online Labs - [MIT License](https://github.com/online-labs/kernel-config/blob/master/LICENSE).
