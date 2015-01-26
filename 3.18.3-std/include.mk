DOCKER_BUILDER ?=	moul/kernel-builder:stable-cross-armhf
ENTER_COMMAND ?=	git checkout v3.18.3 && git log HEAD^..HEAD
