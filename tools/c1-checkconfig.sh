#!/bin/bash
## This tests are perform to validate the ability of the kernel to run on Online-Labs C1 servers

required_configs=(
    BLK_DEV_NBD
    EXT4_FS
    IP_PNP
    IP_PNP_DHCP
    IP_PNP_BOOTP
    MVMDIO
)
# FIXME: check for loadable modules

recommended_configs=(
    IP_PNP_RARP
)

echo "Checking for required CONFIG_* options in ${CONFIG} (LSP=$LSP)"

has_error=0
for config in ${required_configs[@]}; do
    printf "Checking for required CONFIG_$config=y...    "
    if grep "CONFIG_$config=y" ${CONFIG} >/dev/null; then
        echo "Ok"
    else
        echo "ERROR"
        has_error=1
    fi
done
for config in ${recommended_configs[@]}; do
    printf "Checking for recommended CONFIG_$config=y...    "
    if grep "CONFIG_$config=y" ${CONFIG} >/dev/null; then
        echo "Ok"
    else
        echo "WARNING"
    fi
done

if [ "${has_error}" == 1 ]; then
    if [ "$LSP" == 1 ]; then
        echo "The kernel does not match all the mainline requirements, but since it is LSP and has a different configuration, this error is just a warning. Exiting normally"
    else
        echo "The kernel does not match all the requirements."
        exit 1
    fi
else
    echo "All the requirements are met."
fi
