#!/bin/sh
#not bash problem

xbps-install parted wget cryptsetup xtools binfmt-support

ln -s /etc/sv/binfmt-support /var/service/

wget https://repo-default.voidlinux.org/live/current/void-rpi-aarch64-PLATFORMFS-20250202.tar.xz

#Need total wipe
wipefs --all /dev/mmcblk0

parted /dev/mmcblk0 mklabel msdos #Create disk label
parted /dev/mmcblk0 mkpart primary fat32 1M 257M #Create boot partition, 1M should be a suitable offset for most discs
parted /dev/mmcblk0 mkpart primary ext4 257M 100%


#Setup encrypted root
cryptsetup luksFormat /dev/mmcblk0p2
cryptsetup luksOpen /dev/mmcblk0p2 rpiroot

#Setup logical volumes
vgcreate rpiroot /dev/mapper/rpiroot
lvcreate --name swap -L 512M rpiroot
lvcreate --name root -l 100%FREE rpiroot

#Create filesystems 
mkfs.fat /dev/mmcblk0p1
mkfs.ext4 /dev/rpiroot/root
mkswap /dev/rpiroot/swap

#Mount partitions for installation
mount /dev/rpiroot/root /mnt
mkdir /mnt/boot
mount /dev/mmcblk0p1 /mnt/boot

tar xvfp void-rpi-aarch64-PLATFORMFS-20250202.tar.xz -C /mnt #install system
rm void-rpi-aarch64-PLATFORMFS-20250202.tar.xz

#Unmount partitions
umount /mnt/boot
umount /mnt

#Close luks partition
cryptsetup luksClose /dev/mapper/rpiroot
