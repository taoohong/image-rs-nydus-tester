#!/bin/sh

rafs_mnt=$(mount -l | grep rafs | wc -l)
for ((i=0; i<rafs_mnt; i++)) 
do
    umount rafs 
done
echo "umounted all rafs filesystems"

overlay=$(mount -l | grep overlay | wc -l)
for ((i=0; i<overlay; i++))
do
    umount overlay
done
echo "umounted all overlay filesystems"

erofs=$(mount -l | grep erofs | wc -l)
for ((i=0; i<erofs; i++))
do
    umount erofs 
done
echo "umounted all erofs filesystems"


shopt -s extglob
pushd /var/lib/image-rs
rm -rf !(config.json)
popd
rm -rf /var/container_base/*
echo "deleted all files"
