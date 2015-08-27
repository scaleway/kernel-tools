KERNEL ?=		$(patsubst %/,%,$(dir $(wildcard [34]*/.latest)))
-include $(KERNEL)/include.mk

# Default variables
KERNELS ?=		$(wildcard [34].*.*-*)
KERNEL_VERSION ?=	$(shell echo $(KERNEL) | cut -d- -f1)
KERNEL_FLAVOR ?=	$(shell echo $(KERNEL) | cut -d- -f2)
KERNEL_FULL ?=		$(KERNEL_VERSION)-$(KERNEL_FLAVOR)
DOCKER_BUILDER ?=	moul/kernel-builder:stable-cross-armhf
ARCH_CONFIG ?=		mvebu_v7
CONCURRENCY_LEVEL ?=	$(shell grep -m1 cpu\ cores /proc/cpuinfo 2>/dev/null | sed 's/[^0-9]//g' | grep '[0-9]' || sysctl hw.ncpu | sed 's/[^0-9]//g' | grep '[0-9]')
J ?=			-j $(CONCURRENCY_LEVEL)
S3_TARGET ?=		s3://$(shell whoami)/$(KERNEL_FULL)/
CHECKOUT_TARGET ?= 	refs/tags/v$(KERNEL_VERSION)

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL) \
			-e LOCALVERSION_AUTO=no

CCACHE_DIR ?=	$(PWD)/ccache
LINUX_PATH=/usr/src/linux
DOCKER_VOLUMES ?=	-v $(PWD)/$(KERNEL)/.config:/tmp/.config \
			-v $(PWD)/dist/$(KERNEL_FULL):$(LINUX_PATH)/build/ \
			-v $(CCACHE_DIR):/ccache \
			-v $(PWD)/patches:$(LINUX_PATH)/patches:rw \
			-v $(PWD)/$(KERNEL)/patch.sh:$(LINUX_PATH)/patches-apply.sh:ro \
			-v $(PWD)/rules.mk:$(LINUX_PATH)/rules.mk:ro \
			-v $(PWD)/dtbs/scaleway-c1.dts:$(LINUX_PATH)/arch/arm/boot/dts/scaleway-c1.dts:ro \
			-v $(PWD)/dtbs/scaleway-c1-xen.dts:$(LINUX_PATH)/arch/arm/boot/dts/scaleway-c1-xen.dts:ro \
			-v $(PWD)/dtbs/onlinelabs-pbox.dts:$(LINUX_PATH)/arch/arm/boot/dts/onlinelabs-pbox.dts:ro

DOCKER_RUN_OPTS ?=	-it --rm
KERNEL_TYPE ?=		mainline
ENTER_COMMAND ?=	(git show-ref refs/tags/v$(KERNEL_VERSION) >/dev/null || git fetch --tags) && git checkout $(CHECKOUT_TARGET) && git log HEAD^..HEAD
SHELL_EXEC_CMD ?=	make -f rules.mk shell
REVISION ?=		manual
TRAVIS_TAG ?=

all:	help

.PHONY: help
help:
	@echo 'General purpose commands'
	@echo ' menuconfig     KERNEL=4.0.5-std     run "make menuconfig" in the builder container'
	@echo ' oldconfig      KERNEL=4.0.5-std     run "make oldconfig" in the builder container'
	@echo ' olddefconfig   KERNEL=4.0.5-std     run "make olddefconfig" in the builder container'
	@echo ' build          KERNEL=4.0.5-std     run "make build" in the builder container'
	@echo ' shell          KERNEL=4.0.5-std     open a shell in the kernel builder image'
	@echo ' diff           KERNEL=4.0.5-std     show diffs between 2 .config files'
	@echo ' publish_all    S3_TARGET=s3://me/   publish uImage, dtbs, lib, modules on s3'
	@echo ' create         KERNEL=5.1.2-std     create a new kernel directory'


print-%:
	@echo $* = $($*)


info:
	@echo ARCH_CONFIG="$(ARCH_CONFIG)"
	@echo CONCURRENCY_LEVEL="$(CONCURRENCY_LEVEL)"
	@echo DOCKER_ENV="$(DOCKER_ENV)"
	@echo DOCKER_RUN_OPTS="$(DOCKER_RUN_OPTS)"
	@echo DOCKER_VOLUMES="$(DOCKER_VOLUMES)"
	@echo KERNEL="$(KERNEL)"
	@echo KERNEL_FLAVOR="$(KERNEL_FLAVOR)"
	@echo KERNEL_FULL="$(KERNEL_FULL)"
	@echo KERNEL_TYPE="$(KERNEL_TYPE)"
	@echo KERNEL_VERSION="$(KERNEL_VERSION)"
	@echo LINUX_PATH="$(LINUX_PATH)"
	@echo DOCKER_BUILDER="$(DOCKER_BUILDER)"
	@echo ENTER_COMMAND="$(ENTER_COMMAND)"
	@echo S3_TARGET="$(S3_TARGET)"


create:
	@test -d ./$(KERNEL) && echo "  Kernel $(KERNEL) already exists !" && exit 1 || true
	mkdir -p $(KERNEL)
	touch $(KERNEL)/.config $(KERNEL)/patch.sh
	@echo "  Now you can generate a default configuration using:"
	@echo "    - make mvebu_v7_defconfig KERNEL=$(KERNEL)"


oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig dtbs diff cache_stats uImage shell build:: local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		make -f rules.mk ENTER_COMMAND="$(ENTER_COMMAND)" J="$(J)" enter $@ leave


shell_exec::
	docker exec -it `docker ps -f image=$(DOCKER_BUILDER) -f event=start -lq` $(SHELL_EXEC_CMD)


publish_uImage: dist/$(KERNEL_FULL)/uImage
	s3cmd put --acl-public $< $(S3_TARGET)
	wget --read-timeout=3 --tries=0 -O - $(shell s3cmd info $(S3_TARGET)uImage | grep URL | awk '{print $$2}') >/dev/null


publish_all: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* zImage* config* vmlinuz* build.txt; do \
	  s3cmd put --acl-public $$file $(S3_TARGET); \
	done


dist/$(KERNEL_FULL)/lib.tar.gz: dist/$(KERNEL_FULL)/lib
	tar -C dist/$(KERNEL_FULL) -cvzf $@ lib


dist/$(KERNEL_FULL)/include.tar.gz: dist/$(KERNEL_FULL)/include
	tar -C dist/$(KERNEL_FULL) -cvzf $@ include


# dist/$(KERNEL_FULL)/lib dist/$(KERNEL_FULL)/include:	build


qemu:
	qemu-system-arm \
		-M versatilepb \
		-m 256 \
		-initrd ./dist/$(KERNEL_FULL)/initrd.img-* \
		-kernel ./dist/$(KERNEL_FULL)/uImage-* \
		-append "console=tty1"

clean:
	rm -rf dist/$(KERNEL_FULL)


fclean:	clean
	rm -rf dist ccache


local_assets: $(KERNEL)/.config $(KERNEL)/patch.sh dist/$(KERNEL_FULL) ccache


$(KERNEL)/patch.sh: $(KERNEL)
	touch $@
	chmod +x $@


$(KERNEL)/.config:
	@echo "💣 💀    ⚠️ WARNING: Kernel '$(KERNEL)' is not yet initialized."
	exit 1


dist/$(KERNEL_FULL) ccache $(KERNEL):
	mkdir -p $@


.PHONY:	all build run menuconfig clean fclean ccache_stats


## Travis
travis_common:
	#for file in */.config; do bash -n $$file; done
	find . -name "*.bash" | xargs bash -n
	make -n

tools/docker-checkconfig.sh:
	curl -sLo $@ https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh
	chmod +x $@

tools/lxc-checkconfig.sh:
	curl -sLo $@ https://raw.githubusercontent.com/dotcloud/lxc/master/src/lxc/lxc-checkconfig.in
	chmod +x $@

travis_kernel:	local_assets tools/lxc-checkconfig.sh tools/docker-checkconfig.sh
	bash -n $(KERNEL)/.config

	# Optional checks, these checks won't fail but we can see the detail in the Travis build result
	CONFIG=$(KERNEL)/.config GREP=grep ./tools/lxc-checkconfig.sh || true
	CONFIG=$(KERNEL)/.config ./tools/docker-checkconfig.sh || true

	# Checking C1 compatibility
	./tools/verify_kernel_config.pl $(KERNEL_TYPE) $(KERNEL)/.config

	# Disabling make oldconfig check for now because of the memory limit on travis CI builds
	# ./run $(MAKE) oldconfig


# travis_common + travis_kernel for each kernels
travis_check:	travis_common
	echo $(KERNELS)
	for kernel in $(KERNELS); do \
	  make travis_kernel KERNEL=$$kernel || exit 1; \
	done


travis_build:
	$(MAKE) build KERNEL=$(shell echo $(TRAVIS_TAG) | cut -d- -f1,2) REVISION=$(shell echo $(TRAVIS_TAG) | cut -d- -f3)
