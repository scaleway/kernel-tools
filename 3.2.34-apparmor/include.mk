KERNEL_TYPE ?=		lsp
DOCKER_BUILDER ?=	moul/kernel-builder:local-cross-armhf
ENTER_COMMAND ?=	git branch && git checkout -q lsp-v$(KERNEL_VERSION) && git checkout . && git status && git log HEAD^..HEAD


oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig shell build diff::	$(KERNEL)/linux-marvell
	echo $(eval DOCKER_VOLUMES := $(DOCKER_VOLUMES) -v $(PWD)/$(KERNEL)/linux-marvell/.git:$(LINUX_PATH)/.git)


$(KERNEL)/linux-marvell:
	@echo "***"
	@echo "You need to put the closed-source marvell's kernel git here (a symbolic link works)"
	@echo "***"
	@echo
	@exit 1
