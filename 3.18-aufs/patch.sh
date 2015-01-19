#!/bin/bash

set -e

/bin/bash -x patches/patch_mvneta_fix_tx_coalesce.bash
/bin/bash -x patches/patch_aufs.bash
