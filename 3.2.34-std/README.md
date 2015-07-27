# 3.2.34-std

Marvell 3.2.x LSP kernel with standard configuration

# Changelog

## 3.2.34-xx-std (xxxx-xx-xx)

* Use ext4 for ext2/ext3 file systems

## 3.2.34-30-std (2015-04-13)

* Disable MV_XOR ([#67](https://github.com/scaleway/kernel-tools/issues/67))

## 3.2.34-29-std (xxxx-xx-xx)

* Build nf_conntrack as module ([#35](https://github.com/scaleway/kernel-tools/issues/35))
* Add cryptodev support for testing
* Add plenty of new modules ([#26](https://github.com/scaleway/kernel-tools/issues/26))
* Add perf counters


## 3.2.34-xx-std (xxxx-xx-xx)

* Add tasks stats support ([#18](https://github.com/scaleway/kernel-tools/issues/18))
* Add plenty of new modules
* Enable CGROUPS
* Enable NF_CONNTRACK, NF_CONNTRACK_IPV4, NV_DEFRAG_IPV4 and CONFIG_DEVPTS_MULTIPLE_INSTANCES

## 3.2.34 (2014-12-08)

* Bump to Linux 3.2.34 + Marvell LSP patches
  * [linux changelog](https://kernel.org/pub/linux/kernel/v3.x/ChangeLog-3.2.34)
  * Marvell LSP patches are closed source
