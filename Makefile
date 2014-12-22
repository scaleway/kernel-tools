CONFIG ?=		.config-3.18-std
KERNEL ?=		$(shell echo $(CONFIG) | cut -d- -f2)
NAME ?=			moul/kernel-builder:$(KERNEL)-cross-armhf
CONCURRENCY_LEVEL ?=	$(shell grep -m1 cpu\ cores /proc/cpuinfo | sed 's/[^0-9]//g')
J ?=			-j $(CONCURRENCY_LEVEL)

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL)

DOCKER_VOLUMES ?=	-v $(PWD)/$(CONFIG):/tmp/.config \
			-v $(PWD)/dist:/usr/src/linux/build/ \
			-v $(PWD)/ccache:/ccache
DOCKER_RUN_OPTS ?=	-it --rm


all:	build


run:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash


menuconfig:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash -c 'cp /tmp/.config .config && make menuconfig && cp .config /tmp/.config'


defconfig:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash -c 'cp /tmp/.config .config && make mvebu_defconfig && cp .config /tmp/.config'


build:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash -xc ' \
			cp /tmp/.config .config && \
			make $(J) uImage && \
			make $(J) modules && \
			make headers_install INSTALL_HDR_PATH=build && \
			make modules_install INSTALL_MOD_PATH=build && \
			make uinstall INSTALL_PATH=build && \
			cp arch/arm/boot/uImage build/uImage-`cat include/config/kernel.release` \
		'


clean:
fclean:	clean/
	rm -rf dist ccache


local_assets: $(CONFIG) dist/ ccache


$(CONFIG):
	touch $(CONFIG)


dist ccache:
	mkdir -p $@


.PHONY:	all build run menuconfig build
