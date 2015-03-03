KERNEL ?=		$(patsubst %/,%,$(dir $(wildcard 3*/.latest)))
-include $(KERNEL)/include.mk

# Default variables
KERNELS ?=		$(wildcard 3.*)
KERNEL_VERSION ?=	$(shell echo $(KERNEL) | cut -d- -f1)
KERNEL_FLAVOR ?=	$(shell echo $(KERNEL) | cut -d- -f2)
KERNEL_FULL ?=		$(KERNEL_VERSION)-$(KERNEL_FLAVOR)
DOCKER_BUILDER ?=	moul/kernel-builder:stable-cross-armhf
ARCH_CONFIG ?=		mvebu_v7
CONCURRENCY_LEVEL ?=	$(shell grep -m1 cpu\ cores /proc/cpuinfo 2>/dev/null | sed 's/[^0-9]//g' | grep '[0-9]' || sysctl hw.ncpu | sed 's/[^0-9]//g' | grep '[0-9]')
J ?=			-j $(CONCURRENCY_LEVEL)
S3_TARGET ?=		s3://$(shell whoami)/$(KERNEL_FULL)/

DOCKER_ENV ?=		-e LOADADDR=0x8000 \
			-e CONCURRENCY_LEVEL=$(CONCURRENCY_LEVEL) \
			-e LOCALVERSION_AUTO=no

LINUX_PATH=/usr/src/linux
DOCKER_VOLUMES ?=	-v $(PWD)/$(KERNEL)/.config:/tmp/.config \
			-v $(PWD)/dist/$(KERNEL_FULL):$(LINUX_PATH)/build/ \
			-v $(PWD)/ccache:/ccache \
			-v $(PWD)/patches:$(LINUX_PATH)/patches \
			-v $(PWD)/$(KERNEL)/patch.sh:$(LINUX_PATH)/patches-apply.sh \
			-v $(PWD)/dtbs/onlinelabs-c1.dts:$(LINUX_PATH)/arch/arm/boot/dts/onlinelabs-c1.dts
DOCKER_RUN_OPTS ?=	-it --rm
KERNEL_TYPE ?=		mainline
ENTER_COMMAND ?=	(git show-ref --tags | egrep -q "refs/tags/v$(KERNEL_VERSION)$$" || git fetch --tags) && git checkout v$(KERNEL_VERSION) && git log HEAD^..HEAD


all:	build


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


shell::	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		/bin/bash -xec ' \
			$(ENTER_COMMAND) && \
			cp /tmp/.config .config && \
			bash ; \
			cp .config /tmp/.config \
		'


oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig::	local_assets
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		/bin/bash -xec ' \
			$(ENTER_COMMAND) && \
			cp /tmp/.config .config && \
			if [ -f patches-apply.sh ]; then /bin/bash -xe patches-apply.sh; fi && \
			make $@ && \
			cp .config /tmp/.config \
		'


defconfig:	$(ARCH_CONFIG)_defconfig


build::	local_assets
	test -s $(KERNEL)/.config
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		/bin/bash -xec ' \
			$(ENTER_COMMAND) && \
			cp /tmp/.config .config && \
			(printf "\narch/arm/boot/dts/*.dts\nbuild/\n" >> .git/info/exclude || true) && \
			if [ -f patches-apply.sh ]; then /bin/bash -xe patches-apply.sh; fi && \
			make $(J) uImage && \
			make $(J) modules && \
			make headers_install INSTALL_HDR_PATH=build && \
			make modules_install INSTALL_MOD_PATH=build && \
			make uinstall INSTALL_PATH=build && \
			cp arch/arm/boot/uImage build/uImage-`cat include/config/kernel.release` && \
			cp arch/arm/boot/Image build/Image-`cat include/config/kernel.release` && \
			cp arch/arm/boot/zImage build/zImage-`cat include/config/kernel.release` && \
			( wget http://ftp.fr.debian.org/debian/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.0+dfsg-1_amd64.deb -O /tmp/dtc.deb && \
			  dpkg -i /tmp/dtc.deb && \
			  sed -i s/armada-xp-db.dtb/onlinelabs-c1.dtb/g arch/arm/boot/dts/Makefile && \
			  git update-index --assume-unchanged arch/arm/boot/dts/Makefile && \
			  make dtbs && \
			  cp arch/arm/boot/dts/onlinelabs-c1.dtb build/ && \
			  cat arch/arm/boot/zImage arch/arm/boot/dts/onlinelabs-c1.dtb > build/zImage-dts-appended-`cat include/config/kernel.release` && \
			  mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux-`cat include/config/kernel.release`" -d build/zImage-dts-appended-`cat include/config/kernel.release` uImage-dts-appended && \
			  mv uImage-dts-appended build/uImage-dts-appended-`cat include/config/kernel.release` \
			) && \
			( echo "=== $(KERNEL_FULL) - built on `date`" && \
			  echo "=== gcc version" && \
			  gcc --version && \
			  echo "=== file listing" && \
			  find build -type f -ls && \
			  echo "=== sizes" && \
			  du -sh build/* \
			) > build/build.txt \
		'


publish_all: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* zImage* config* vmlinuz* build.txt; do \
	  s3cmd put --acl-public $$file $(S3_TARGET); \
	done


dist/$(KERNEL_FULL)/lib.tar.gz: dist/$(KERNEL_FULL)/lib
	tar -C dist/$(KERNEL_FULL) -cvzf $@ lib


dist/$(KERNEL_FULL)/include.tar.gz: dist/$(KERNEL_FULL)/include
	tar -C dist/$(KERNEL_FULL) -cvzf $@ include


dist/$(KERNEL_FULL)/lib dist/$(KERNEL_FULL)/include:	build


ccache_stats:
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		ccache -s


diff::
	docker run $(DOCKER_RUN_OPTS) $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		/bin/bash -xec ' \
			$(ENTER_COMMAND) && \
			make $(ARCH_CONFIG)_defconfig && \
			mv .config .defconfig && \
			cp /tmp/.config .config && \
			diff <(<.defconfig grep "^[^#]" | sort) <(<.config grep "^[^#]" | sort) \
		'


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


$(KERNEL)/.config: $(KERNEL)
	touch $(KERNEL)/.config


dist/$(KERNEL_FULL) ccache $(KERNEL):
	mkdir -p $@


.PHONY:	all build run menuconfig build clean fclean ccache_stats


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

travis_kernel:	local_assets travis_prepare tools/lxc-checkconfig.sh tools/docker-checkconfig.sh
	bash -n $(KERNEL)/.config

	# Optional checks, these checks won't fail but we can see the detail in the Travis build result
	CONFIG=$(KERNEL)/.config GREP=grep ./tools/lxc-checkconfig.sh || true
	CONFIG=$(KERNEL)/.config ./tools/docker-checkconfig.sh || true

	# Checking C1 compatibility
	./tools/verify_kernel_config.pl $(KERNEL_TYPE) $(KERNEL)/.config

	# Disabling make oldconfig check for now because of the memory limit on travis CI builds
	# ./run $(MAKE) oldconfig


# travis_common + travis_kernel for each kernels
travis:	travis_common
	echo $(KERNELS)
	for kernel in $(KERNELS); do \
	  make travis_kernel KERNEL=$$kernel || exit 1; \
	done


# Docker in Travis toolsuite
travis_prepare:	./run
./run:
	# Disabled for now (see travis_kernel below)
	# curl -sLo - https://github.com/moul/travis-docker/raw/master/install.sh | sh -xe
	exit 0
