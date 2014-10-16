Kernel Config
=============

https://community.cloud.online.net/t/official-linux-kernel-new-modules-optimizations-hacks/226

The kernel is built with the official mainline kernel, here are the .config files used.

Modifications
-------------

The only things we add are:

- a kernel module to simulate some virtualization features: handling serial console, being able to soft reset a node from the API
- a dts file, so the kernel can understand our hardware

Releases
========

2014-10-15 - 3.17.0-85
----------------------

- used .config: https://github.com/online-labs/kernel-config/blob/3.17.0-85/.config-3.17-std
- community discuttion: https://community.cloud.online.net/t/official-linux-kernel-new-modules-optimizations-hacks/226/6?u=manfred
- kernel commit: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tag/?id=v3.17
