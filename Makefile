KERNEL ?=		$(patsubst %/,%,$(dir $(wildcard armv7l/*-*/.latest)))
-include $(KERNEL)/include.mk

# Default variables
REVISION ?=		manual
KERNELS ?=		$(wildcard x86_64/*-* armv7l/*-*)
KERNEL_ARCH ?=		$(shell echo $(KERNEL) | cut -d/ -f1)
-include $(KERNEL_ARCH)/include.mk
KERNEL_VERSION ?=	$(shell echo $(KERNEL) | cut -d/ -f2 | cut -d- -f1)
KERNEL_FLAVOR ?=	$(shell echo $(KERNEL) | cut -d/ -f2 | cut -d- -f2)
KERNEL_FULL ?=		$(KERNEL_ARCH)-$(KERNEL_VERSION)-$(KERNEL_FLAVOR)-$(REVISION)
DOCKER_BUILDER ?=	moul/kernel-builder:latest
CONCURRENCY_LEVEL ?=	$(shell grep -m1 cpu\ cores /proc/cpuinfo 2>/dev/null | sed 's/[^0-9]//g' | grep '[0-9]' || sysctl hw.ncpu | sed 's/[^0-9]//g' | grep '[0-9]')
J ?=			-j $(CONCURRENCY_LEVEL)
S3_TARGET ?=		s3://$(shell whoami)/$(KERNEL_FULL)/
STORE_HOSTNAME ?=	store.scw.42.am
STORE_USERNAME ?=	$(shell whoami)
STORE_TARGET ?=		$(STORE_HOSTNAME):store/kernels/$(KERNEL_FULL)
CHECKOUT_TARGET ?= 	refs/tags/v$(KERNEL_VERSION)
LOCALVERSION ?=		-$(KERNEL_FLAVOR)-$(REVISION)
KBUILD_BUILD_USER ?=	$(shell whoami)
KBUILD_BUILD_HOST ?=	$(shell hostname)


CCACHE_DIR ?=	$(PWD)/ccache
LINUX_PATH=/usr/src/linux

KERNEL_TYPE ?=		mainline
ENTER_COMMAND ?=	(git show-ref refs/tags/v$(KERNEL_VERSION) >/dev/null || git fetch --tags) && git checkout $(CHECKOUT_TARGET) && git log HEAD^..HEAD
SHELL_EXEC_CMD ?=	make -f rules.mk shell
TRAVIS_TAG ?=

all:	help

.PHONY: help
help:
	@echo 'General purpose commands'
	@echo ' menuconfig       KERNEL=4.0.5-std       run "make menuconfig" in the builder container'
	@echo ' oldconfig        KERNEL=4.0.5-std       run "make oldconfig" in the builder container'
	@echo ' olddefconfig     KERNEL=4.0.5-std       run "make olddefconfig" in the builder container'
	@echo ' build            KERNEL=4.0.5-std       run "make build" in the builder container'
	@echo ' shell            KERNEL=4.0.5-std       open a shell in the kernel builder image'
	@echo ' diff             KERNEL=4.0.5-std       show diffs between 2 .config files'
	@echo ' publish_on_s3    S3_TARGET=s3://me/     publish uImage, dtbs, lib, modules on s3'
	@echo ' publish_on_store STORE_TARGET=str.io/me publish uImage, dtbs, lib, modules on store'
	@echo ' create           KERNEL=5.1.2-std       create a new kernel directory'


print-%:
	@echo $* = $($*)


info:
	@echo "KERNEL			$(KERNEL)"
	@echo "KERNEL_FLAVOR		$(KERNEL_FLAVOR)"
	@echo "KERNEL_FULL		$(KERNEL_FULL)"
	@echo "KERNEL_TYPE		$(KERNEL_TYPE)"
	@echo "KERNEL_VERSION		$(KERNEL_VERSION)"
	@echo "KERNEL_ARCH		$(KERNEL_ARCH)"
	@echo "ARCH_CONFIG		$(ARCH_CONFIG)"
	@echo "CONCURRENCY_LEVEL	$(CONCURRENCY_LEVEL)"
	@echo "DOCKER_ENV		$(DOCKER_ENV)"
	@echo "DOCKER_VOLUMES		$(DOCKER_VOLUMES)"
	@echo "LINUX_PATH		$(LINUX_PATH)"
	@echo "DOCKER_BUILDER		$(DOCKER_BUILDER)"
	@echo "ENTER_COMMAND		$(ENTER_COMMAND)"
	@echo "S3_TARGET		$(S3_TARGET)"


create:
	@test -d ./$(KERNEL) && echo "  Kernel $(KERNEL) already exists !" && exit 1 || true
	mkdir -p $(KERNEL)
	touch $(KERNEL)/.config $(KERNEL)/patch.sh
	@echo "  Now you can generate a default configuration using:"
	@echo "    - make mvebu_v7_defconfig KERNEL=$(KERNEL)"


shell menuconfig:: local_assets
	docker run -it $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		make -f rules.mk ENTER_COMMAND="$(ENTER_COMMAND)" J="$(J)" enter $@ leave


oldconfig olddefconfig $(ARCH_CONFIG)_defconfig dtbs diff cache_stats uImage build bzImage:: local_assets
	docker run -i $(DOCKER_ENV) $(DOCKER_VOLUMES) $(DOCKER_BUILDER) \
		make -f rules.mk ENTER_COMMAND="$(ENTER_COMMAND)" J="$(J)" enter $@ leave


shell_exec::
	docker exec -it `docker ps -f image=$(DOCKER_BUILDER) -f event=start -lq` $(SHELL_EXEC_CMD)


publish_uImage_on_s3: dist/$(KERNEL_FULL)/uImage
	s3cmd put --acl-public $< $(S3_TARGET)
	wget --read-timeout=3 --tries=0 -O - $(shell s3cmd info $(S3_TARGET)uImage | grep URL | awk '{print $$2}') >/dev/null


publish_on_s3: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* *zImage* config* vmlinuz* build.txt dtbs/*; do \
	  s3cmd put --acl-public $$file $(S3_TARGET); \
	done


publish_on_store: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* *zImage* config* vmlinuz* build.txt; do \
	  if [ -f $$file ]; then \
	    rsync -avze ssh $$file $(STORE_TARGET); \
	  fi; \
	done


publish_on_store_ftp: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* *zImage* config* vmlinuz* build.txt dtbs/*; do \
	  curl -T "$$file" --netrc ftp://$(STORE_HOSTNAME)/kernels/$(KERNEL_FULL)/; \
	done


publish_on_store_sftp: dist/$(KERNEL_FULL)/lib.tar.gz dist/$(KERNEL_FULL)/include.tar.gz
	cd dist/$(KERNEL_FULL) && \
	for file in lib.tar.gz include.tar.gz uImage* *zImage* config* vmlinuz* build.txt dtbs/*; do \
	  lftp -u $(STORE_USERNAME) -p 2222 sftp://$(STORE_HOSTNAME) -e "mkdir store/kernels/$(KERNEL_FULL); cd store/kernels/$(KERNEL_FULL); put $$file; bye"; \
	done


dist/$(KERNEL_FULL)/lib.tar.gz: dist/$(KERNEL_FULL)/lib
	tar -C dist/$(KERNEL_FULL) -cvzf $@ lib


dist/$(KERNEL_FULL)/include.tar.gz: dist/$(KERNEL_FULL)/include
	tar -C dist/$(KERNEL_FULL) -cvzf $@ include


# dist/$(KERNEL_FULL)/lib dist/$(KERNEL_FULL)/include:	build


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
	./tools/verify_kernel_config.pl $(KERNEL_ARCH)-$(KERNEL_TYPE) $(KERNEL)/.config

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
