#!/bin/bash

urls=""
urls="$urls https://raw.githubusercontent.com/online-labs/kernel-config/master/patches/patch_mvneta_fix_tx_coalesce.bash"

for url in $urls; do
    wget -qO - $url | bash -xe
done
