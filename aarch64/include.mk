DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL) \
			-e ARCH=arm64 \
			-e CROSS_COMPILE="ccache aarch64-linux-gnu-" \
			-e KERNEL_ARCH=$(KERNEL_ARCH) \
			-e KBUILD_BUILD_USER=$(KBUILD_BUILD_USER) \
			-e KBUILD_BUILD_HOST=$(KBUILD_BUILD_HOST) \
			-e LOCALVERSION=$(LOCALVERSION)

DOCKER_VOLUMES ?=	-v $(PWD)/$(KERNEL)/.config:/tmp/.config \
			-v $(PWD)/dist/$(KERNEL_FULL):$(LINUX_PATH)/build/ \
			-v $(CCACHE_DIR):/ccache \
			-v $(PWD)/patches:$(LINUX_PATH)/patches:rw \
			-v $(PWD)/$(KERNEL)/patch.sh:$(LINUX_PATH)/patches-apply.sh:ro \
			-v $(PWD)/rules.mk:$(LINUX_PATH)/rules.mk:ro

qemu:
	qemu-system-aarch64 \
		-M versatilepb \
		-m 256 \
		-initrd ./dist/$(KERNEL_FULL)/initrd.img-* \
		-kernel ./dist/$(KERNEL_FULL)/Image-* \
		-append "console=tty1"
