#!/bin/bash

KERNEL_VERSION=5.15.86
BUSYBOX_VERSION=1.35.0

mkdir linux
cd linux
    mkdir kernel initrd
    cd kernel
        KERNEL_MAJOR=$(echo $KERNEL_VERSION | sed 's/\([0-9]*\)[^0-9].*/\1/')
        wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/linux-$KERNEL_VERSION.tar.xz
        tar -xvf linux-$KERNEL_VERSION.tar.xz
        cd linux-$KERNEL_VERSION
            make defconfig
            make -j$(nproc) || exit
            cp arch/x86_64/boot/bzImage ../../vmlinuz
            cd ..
        cd ..
    wget https://www.busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
    tar -xvf busybox-$BUSYBOX_VERSION.tar.bz2
    cd busybox-$BUSYBOX_VERSION
		make defconfig
		sed 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' -i .config
		make -j$(nproc) busybox || exit
	cd ..

    cp busybox-$BUSYBOX_VERSION/busybox initrd/busybox
    cd initrd
        mkdir bin
        mv busybox bin/
        echo '#!/bin/busybox sh
/bin/busybox --install -s /bin
mount -t devtmpfs udev /dev
mount -t sysfs sysfs /sys
mount -t proc proc /proc
sysctl -w kernel.printk="2 4 1 7"
exec /bin/sh' > init
        mkdir dev sys proc
        chmod -R 777 .
        find .|cpio -o -H newc>../initrd.img
        cd ..
    wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/syslinux-6.04-pre1.tar.xz
    mkdir cdboot
    tar -xvf syslinux-6.04-pre1.tar.xz
    mv syslinux-6.04-pre1/ syslinux/
    cp vmlinuz initrd.img syslinux/bios/core/isolinux.bin cd syslinux/bios/com32/elflink/ldlinux/ldlinux.c32 cdboot/
    cd cdboot
        mkdir isolinux
        mv isolinux.bin ldlinux.c32 isolinux/
        cd isolinux
            echo 'DEFAULT linux
LABEL linux
    KERNEL /vmlinuz
    APPEND initrd=/initrd.img' > isolinux.cfg
            cd ..
        cd ..
    mkisofs -o linux.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table cdboot/
