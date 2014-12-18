run:	uImage
	qemu-system-arm -M versatilepb -cpu cortex-a8 -m 1024M -kernel $< -append "verbose panic=5 earlyprintk"

uImage:
	wget -q http://fr-1.storage.online.net/test-bootscripts/manfred-uImage-3.2.34-std -O $@
