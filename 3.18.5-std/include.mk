DOCKER_BUILDER ?=	moul/kernel-builder:stable-cross-armhf
ENTER_COMMAND ?=	git fetch --tags && git checkout v$(KERNEL_VERSION) && git log HEAD^..HEAD
