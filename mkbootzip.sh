#!/bin/sh

# Build script for HP TouchPad Debian moboot images
# Builds both a standalone Debian image and a "DebiAndroid" chroot image
# For standalone, the Debian root filesystem must be in an LVM volume called debian-root
# For chroot, the Debian root filesystem must be in the cm-data (/data on Android) partition as /data/debian

# remove old modules
echo "Cleaning Modules Directory"
rm -rf ./modules/*

# compile the kernel
echo "Building kernel"
cd kernel
#make debian_tenderloin_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j5 uImage
make INSTALL_MOD_PATH=../modules modules_install
cd ..

# compile the backports
echo "Building backports"
cd backports
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- KLIB_BUILD=../kernel KLIB=../modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- KLIB_BUILD=../kernel KLIB=../modules -j5
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- KLIB_BUILD=../kernel KLIB=../modules install
cd ..

# build the chroot ramdisk
echo "Building chroot ramdisk"
cd ramdisk-chroot
find . -print | cpio -H newc -o | gzip -9 > ../ramdisk-chroot.cpio.gz
cd ..
mkimage -A arm -O linux -T ramdisk -C none -a 0x60000000 -e 0x60000000 -n "Image" -d ramdisk-chroot.cpio.gz uRamdisk-chroot

# build the standalone ramdisk
echo "Building standalone ramdisk"
cd ramdisk-standalone
find . -print | cpio -H newc -o | gzip -9 > ../ramdisk-standalone.cpio.gz
cd ..
mkimage -A arm -O linux -T ramdisk -C none -a 0x60000000 -e 0x60000000 -n "Image" -d ramdisk-standalone.cpio.gz uRamdisk-standalone

# make the boot image
echo "Building boot images"
mkimage -A arm -O linux -T multi -a 0x40208000 -e 0x40208000 -C none -n "multi image" -d kernel/arch/arm/boot/uImage:uRamdisk-chroot  uImage.DebiAndroid
mkimage -A arm -O linux -T multi -a 0x40208000 -e 0x40208000 -C none -n "multi image" -d kernel/arch/arm/boot/uImage:uRamdisk-standalone uImage.Debian 
