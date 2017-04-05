ARCH_CONFIG ?=		mvebu_v7

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL) \
			-e ARCH=arm \
			-e CROSS_COMPILE="ccache arm-linux-gnueabihf-" \
			-e KERNEL_ARCH=$(KERNEL_ARCH) \
			-e KBUILD_BUILD_USER=$(KBUILD_BUILD_USER) \
			-e KBUILD_BUILD_HOST=$(KBUILD_BUILD_HOST) \
			-e LOCALVERSION=$(LOCALVERSION)

DOCKER_VOLUMES ?=	-v $(PWD)/$(KERNEL)/.config:/tmp/.config \
			-v $(PWD)/dist/$(KERNEL_FULL):$(LINUX_PATH)/build/ \
			-v $(CCACHE_DIR):/ccache \
			-v $(PWD)/patches:$(LINUX_PATH)/patches:rw \
			-v $(PWD)/$(KERNEL)/patch.sh:$(LINUX_PATH)/patches-apply.sh:ro \
			-v $(PWD)/rules.mk:$(LINUX_PATH)/rules.mk:ro \
			-v $(PWD)/dtbs/scaleway-c1.dts:$(LINUX_PATH)/arch/arm/boot/dts/scaleway-c1.dts:ro

qemu:
	qemu-system-arm \
		-M versatilepb \
		-m 256 \
		-initrd ./dist/$(KERNEL_FULL)/initrd.img-* \
		-kernel ./dist/$(KERNEL_FULL)/uImage-* \
		-append "console=tty1"
