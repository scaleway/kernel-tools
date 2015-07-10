KERNEL_TYPE ?=		std
DOCKER_BUILDER ?=	moul/kernel-builder:local-cross-armhf
ENTER_COMMAND ?=	true


oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig shell build diff::	$(KERNEL)/linux-git
	echo $(eval DOCKER_VOLUMES := $(DOCKER_VOLUMES) -v $(PWD)/$(KERNEL)/linux-git:$(LINUX_PATH))


$(KERNEL)/linux-git:
	@echo "***"
	@echo "You need to put the linux kernel sources git here (a symbolic link works)"
	@echo "***"
	@echo
	@exit 1
