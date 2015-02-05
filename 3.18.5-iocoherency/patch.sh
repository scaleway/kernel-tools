#!/usr/bin/env bash

# Re-enable hardware IO-coherency
git revert -n 1f20756ce695ee56c2899e95757497d9c1cc8bbb

patch -p1 < patches/patch-cpuidle.patch
