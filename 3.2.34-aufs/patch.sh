#!/usr/bin/env bash

for file in patches/aufs-aufs3-debian-3.2/*
do
    patch -p1 < $file
done

