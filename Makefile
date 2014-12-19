CONFIG ?=	.config-3.18-std
KERNEL ?=	$(shell echo $(CONFIG) | cut -d- -f2)
NAME ?=		moul/kernel-builder:$(KERNEL)-cross-armhf
NPROC ?=	$(shell echo `nproc` ' * 2' | bc)


run:
	docker run -it --rm \
		-v $(PWD)/$(CONFIG):/usr/src/linux/.config \
		$(NAME) \
		/bin/bash


menuconfig:
	docker run -it --rm \
		-v $(PWD)/$(CONFIG):/tmp/.config \
		$(NAME) \
		/bin/bash -c 'cp /tmp/.config .config && make menuconfig && cp .config /tmp/.config'


build:
	mkdir -p dist
	docker run -it --rm \
		-v $(PWD)/$(CONFIG):/usr/src/linux/.config \
		-v $(PWD)/dist:/usr/src/linux/build/ \
		$(NAME) \
		make -j $(NPROC) uImage modules LOADADDR=0x8000
