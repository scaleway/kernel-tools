#!/bin/bash

set -e

/bin/bash -x patches/patch_mvneta_fix_tx_coalesce.bash
patch -p1 < patches/patch-cpuidle.patch