CONFIG ?=	.config-3.18-std
KERNEL ?=	$(shell echo $(CONFIG) | cut -d- -f2)
NAME ?=		moul/kernel-builder:$(KERNEL)-cross-armhf
NPROC ?=	$(shell echo `nproc` ' * 2' | bc 2>/dev/null || nproc)

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e INSTALL_HDR_PATH=build/ \
			-e INSTALL_MOD_PATH=build/ \
			-e INSTALL_PATH=build/
DOCKER_VOLUMES ?=	-v $(PWD)/$(CONFIG):/usr/src/linux/.config \
			-v $(PWD)/dist:/usr/src/linux/build/
DOCKER_RUN_OPTS ?=	-it --rm


all:	build


run:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash


menuconfig:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash -c 'cp /tmp/.config .config && make menuconfig && cp .config /tmp/.config'


build:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		make -j $(NPROC) uImage modules headers_install modules_install


local_assets: $(CONFIG) dist/


$(CONFIG):
	touch $(CONFIG)


dist:
	mkdir -p $@


.PHONY:	all build run menuconfig build
