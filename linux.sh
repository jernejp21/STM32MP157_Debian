#!/bin/bash

#ARM Cross Compiler: GCC
wget -c https://mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/11.1.0/x86_64-gcc-11.1.0-nolibc-arm-linux-gnueabi.tar.xz
tar -xvf x86_64-gcc-11.1.0-nolibc-arm-linux-gnueabi.tar.xz
export CC=`pwd`/gcc-11.1.0-nolibc/arm-linux-gnueabi/bin/arm-linux-gnueabi-

#Bootloader: U-Boot
git clone -b v2022.04-rc4 https://github.com/u-boot/u-boot --depth=1
cd u-boot/
#Configure and build
make ARCH=arm CROSS_COMPILE=${CC} distclean
make ARCH=arm CROSS_COMPILE=${CC} stm32mp15_trusted_defconfig
make ARCH=arm CROSS_COMPILE=${CC} DEVICE_TREE=stm32mp157a-dk1 all
cd ..

#Bootloader: Trusted Firmware A (TF-A)
git clone -b v2.5 https://github.com/ARM-software/arm-trusted-firmware --depth=1
cd arm-trusted-firmware/
#Configure and build
make CROSS_COMPILE=${CC} realclean
make CROSS_COMPILE=${CC} PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 AARCH32_SP=sp_min DTB_FILE_NAME=stm32mp157a-dk1.dtb STM32MP_SDMMC=1
cd ..

#Linux Kernel
git clone https://github.com/RobertCNelson/armv7-lpae-multiplatform ./kernelbuildscripts
cd kernelbuildscripts/
git checkout origin/v5.15.x -b tmp
#Build the kernel
./build_kernel.sh
cd ..

#Root File System - Debian 11
wget -c https://rcn-ee.com/rootfs/eewiki/minfs/debian-11.3-minimal-armhf-2022-04-15.tar.xz
tar -xvf debian-11.3-minimal-armhf-2022-04-15.tar.xz

#Debian; Root File System:
sudo mkdir rootfs
sudo tar xfvp ./debian-*-*-armhf-*/armhf-rootfs-*.tar -C rootfs/

export kernel_version="5.15.32-armv7-lpae-x23"
#user@localhost:~$
sudo mkdir -p rootfs/boot/extlinux/
sudo sh -c "echo 'label Linux ${kernel_version}' > rootfs/boot/extlinux/extlinux.conf"
sudo sh -c "echo '    kernel /boot/vmlinuz-${kernel_version}' >> rootfs/boot/extlinux/extlinux.conf"
sudo sh -c "echo '    append console=ttySTM0,115200 root=/dev/mmcblk0p4 ro rootfstype=ext4 rootwait' >> rootfs/boot/extlinux/extlinux.conf"
sudo sh -c "echo '    fdtdir /boot/dtbs/${kernel_version}/' >> rootfs/boot/extlinux/extlinux.conf"
#user@localhost:~$
sudo cp -v ./kernelbuildscripts/deploy/${kernel_version}.zImage rootfs/boot/vmlinuz-${kernel_version}
#user@localhost:~$
sudo mkdir -p rootfs/boot/dtbs/${kernel_version}/
sudo tar -xvf ./kernelbuildscripts/deploy/${kernel_version}-dtbs.tar.gz -C rootfs/boot/dtbs/${kernel_version}/
#user@localhost:~$
sudo tar -xvf ./kernelbuildscripts/deploy/${kernel_version}-modules.tar.gz -C rootfs/
#user@localhost:~/$
sudo sh -c "echo '/dev/mmcblk0p4  /  auto  errors=remount-ro  0  1' >> rootfs/etc/fstab"

sudo mkdir tmp_rootfs
dd if=/dev/zero of=rootfs.ext4 bs=1M count=2000
sudo mkfs.ext4 rootfs.ext4

sudo mount -o loop rootfs.ext4 tmp_rootfs
sudo cp -v -r -p rootfs/* tmp_rootfs
sync

sudo umount tmp_rootfs

wget https://github.com/pengutronix/genimage/releases/download/v15/genimage-15.tar.xz
tar -xvf genimage-15.tar.xz
#git clone https://github.com/pengutronix/genimage.git
cd genimage-15
unset CC
./configure
make all
cd ..
mkdir root
mkdir tmp
./genimage-15/genimage --inputpath . --outputpath . --config genimage.cfg --rootpath root --tmppath tmp

sudo rm -rf root rootfs tmp tmp_rootfs
