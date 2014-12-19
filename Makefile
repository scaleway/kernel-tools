CONFIG ?=		.config-3.18-std
KERNEL ?=		$(shell echo $(CONFIG) | cut -d- -f2)
NAME ?=			moul/kernel-builder:$(KERNEL)-cross-armhf
CONCURRENCY_LEVEL ?=	$(shell grep -m1 cpu\ cores /proc/cpuinfo | sed 's/[^0-9]//g')
J ?=			-j $(CONCURRENCY_LEVEL)

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e INSTALL_HDR_PATH=build/ \
			-e INSTALL_MOD_PATH=build/ \
			-e INSTALL_PATH=build/ \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL)

DOCKER_VOLUMES ?=	-v $(PWD)/$(CONFIG):/usr/src/linux/.config \
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


build:	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(NAME) \
		/bin/bash -c 'make $(J) uImage && make $(J) modules && make headers_install && make modules_install'


clean:
fclean:	clean/
	rm -rf dist ccache


local_assets: $(CONFIG) dist/ ccache


$(CONFIG):
	touch $(CONFIG)


dist ccache:
	mkdir -p $@


.PHONY:	all build run menuconfig build
