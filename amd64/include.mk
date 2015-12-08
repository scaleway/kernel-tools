DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL) \
			-e LOCALVERSION_AUTO=no
DOCKER_VOLUMES ?=	-v $(PWD)/$(KERNEL)/.config:/tmp/.config \
			-v $(PWD)/dist/$(KERNEL_FULL):$(LINUX_PATH)/build/ \
			-v $(CCACHE_DIR):/ccache \
			-v $(PWD)/patches:$(LINUX_PATH)/patches:rw \
			-v $(PWD)/$(KERNEL)/patch.sh:$(LINUX_PATH)/patches-apply.sh:ro \
			-v $(PWD)/rules.mk:$(LINUX_PATH)/rules.mk:ro

qemu:
	@echo "No implemented."
	@exit 1
