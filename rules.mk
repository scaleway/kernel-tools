KERNEL_VERSION =	$(shell (test -f include/config/kernel.release || $(MAKE) include/config/kernel.release &>/dev/null); cat include/config/kernel.release)
ARCH_CONFIG ?=		mvebu_v7
J ?=			-j $(CONCURRENCY_LEVEL)


all:
	@echo "This Makefile is used inside Docker"


.PHONY: all enter leave oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig dtbs build ccache_stats shell defconfig uImage diff uImage-appended


print-%:
	@echo $* = $($*)


enter:
	$(ENTER_COMMAND)
	cp /tmp/.config .config


leave:
	cp .config /tmp/.config


oldconfig olddefconfig menuconfig $(ARCH_CONFIG)_defconfig: apply-patches
	$(MAKE) $@


/usr/bin/dtc:
	wget http://ftp.fr.debian.org/debian/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.0+dfsg-1_amd64.deb -O /tmp/dtc.deb
	dpkg -i /tmp/dtc.deb
	rm -f /tmp/dtc.deb


apply-patches:
	@if [ -f patches-apply.sh -a ! -f patches-applied ]; then \
	  echo /bin/bash -xe patches-apply.sh; \
	  /bin/bash -xe patches-apply.sh || exit 1; \
	  printf "\narch/arm/boot/dts/*.dts\nbuild/\nrules.mk\n" >> .git/info/exclude || true; \
	  touch patches-applied; \
	fi


build_armv7l:
	@mv build/build.txt build/build-prev.txt || true
	$(MAKE) -f rules.mk uImage dtbs build_info 2>&1 | tee build/build.txt


build_x86_64:
	@mv build/build.txt build/build-prev.txt || true
	$(MAKE) -f rules.mk bzImage build_info 2>&1 | tee build/build.txt


build: build_$(KERNEL_ARCH)


dtbs: /usr/bin/dtc apply-patches
	-printf "\narch/arm/boot/dts/*.dts\nbuild/\n" >> .git/info/exclude || true
	sed -i "s/armada-xp-db.dtb/scaleway-c1.dtb\ onlinelabs-pbox.dtb/g" arch/arm/boot/dts/Makefile
	git update-index --assume-unchanged arch/arm/boot/dts/Makefile
	$(MAKE) dtbs
	cp arch/arm/boot/dts/onlinelabs-*.dtb arch/arm/boot/dts/scaleway-*.dtb build/


ccache_stats:
	ccache -s


shell:
	bash


defconfig:	$(ARCH_CONFIG)_defconfig

bzImage: apply-patches
	make $(J) bzImage
	make $(J) modules
	make headers_install INSTALL_HDR_PATH=build
	cd build/ && tar cf include.tar include
	make modules_install INSTALL_MOD_PATH=build
	cd build/ && tar cf lib.tar lib
	make install INSTALL_PATH=build
	cp include/config/kernel.release build/kernel.release
	echo $(KERNEL_VERSION)
	#find . -name "*Image*"
	cp arch/x86_64/boot/bzImage build/bzImage-$(KERNEL_VERSION)
	cp -f build/bzImage-$(KERNEL_VERSION) build/bzImage


uImage: apply-patches
	make $(J) uImage
	make $(J) modules
	make headers_install INSTALL_HDR_PATH=build
	cd build/ && tar cf include.tar include
	make modules_install INSTALL_MOD_PATH=build
	cd build/ && tar cf lib.tar lib
	make uinstall INSTALL_PATH=build
	cp include/config/kernel.release build/kernel.release
	echo $(KERNEL_VERSION)
	cp arch/arm/boot/uImage build/uImage-$(KERNEL_VERSION)
	cp -f build/uImage-$(KERNEL_VERSION) build/uImage
	cp arch/arm/boot/Image build/Image-$(KERNEL_VERSION)
	cp -f build/Image-$(KERNEL_VERSION) build/Image
	cp arch/arm/boot/zImage build/zImage-$(KERNEL_VERSION)
	cp -f build/zImage-$(KERNEL_VERSION) build/zImage


build_info:
	@echo "=== $(KERNEL_FULL) - built on `date`"
	@echo "=== gcc version"
	gcc --version
	@echo "=== file listing"
	find build -type f -ls
	@echo "=== sizes"
	du -sh build/*
	du -sh build


diff:
	cp .config .bkpconfig
	$(MAKE) $(ARCH_CONFIG)_defconfig
	mv .config .defconfig
	mv .bkpconfig .config
	diff <(<.defconfig grep "^[^#]" | sort) <(<.config grep "^[^#]" | sort)


uImage-appended: apply-patches
	cat build/zImage build/scaleway-c1.dtb > build/zImage-c1-dts-appended-$(KERNEL_VERSION)
	cp -f build/zImage-c1-dts-appended-$(KERNEL_VERSION) build/zImage-c1-dts-appended
	mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux-$(KERNEL_VERSION)" -d build/zImage-pbox-dts-appended-$(KERNEL_VERSION) uImage-pbox-dts-appended
	mv uImage-pbox-dts-appended build/uImage-pbox-dts-appended-$(KERNEL_VERSION)
	cp -f build/uImage-pbox-dts-appended-$(KERNEL_VERSION) build/uImage-pbox-dts-appended

	cat build/zImage build/onlinelabs-pbox.dtb > build/zImage-pbox-dts-appended-$(KERNEL_VERSION)
	cp -f build/zImage-pbox-dts-appended-$(KERNEL_VERSION) build/zImage-pbox-dts-appended
	mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n "Linux-$(KERNEL_VERSION)" -d build/zImage-c1-dts-appended-$(KERNEL_VERSION) uImage-c1-dts-appended
	mv uImage-c1-dts-appended build/uImage-c1-dts-appended-$(KERNEL_VERSION)
	cp -f build/uImage-c1-dts-appended-$(KERNEL_VERSION) build/uImage-c1-dts-appended
