#!/bin/sh

#Install dependencies on host system
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

#Create fstab
echo $(lsblk -n -o UUID /dev/rpiroot/swap)	/              	ext4      	rw        	0 1 >> /mnt/etc/fstab
echo $(lsblk -n -o UUID /dev/rpiroot/root)	none           	swap      	defaults  	0 0 >> /mnt/etc/fstab

#Setup boot options
echo "initramfs initrd.img followkernel" >> /mnt/boot/config.txt
#Setup crypttab
echo rpiroot /dev/mmcblk0p2 /boot/volume.key luks >> /mnt/etc/crypttab

#Setup Kernel vars
truncate -s 0 /mnt/boot/cmdline.txt
echo rd.lvm.vg=rpiroot rd.luks.uuid=$(lsblk -n -o UUID /dev/mmcblk0p2) root=/dev/rpiroot/root rw console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 smsc95xx.turbo_mode=N dwc_otg.lpm_enable=0 loglevel=4 elevator=noop >> /mnt/boot/cmdline.txt

#Install requirements on the encrypted system
xchroot /mnt xbps-install -Suvy cryptsetup lvm2 linux-base linux-headers dracut

#Add dropbear ssh setttings to dracut
cp configs/10-crypt.conf /mnt/etc/dracut.conf.d/

dd bs=1 count=64 if=/dev/urandom of=/mnt/boot/volume.key

chmod 000 /mnt/boot/volume.key 

cryptsetup luksAddKey /dev/mmcblk0p2 /mnt/boot/volume.key

#Make sure package is up to date and remove RPI optimisations
xchroot /mnt xbps-install -Suvy
xchroot /mnt xbps-remove rpi-base
xchroot /mnt xbps-remove rpi-kernel

#Generate initramfs
xchroot depmod $(ls -S /usr/lib/modules/ | tail -1)
xchroot /mnt dracut -f /boot/initrd.img $(ls -S /usr/lib/modules/ | tail -1)


#Unmount partitions
umount /mnt/boot
umount /mnt

#Close luks partition
cryptsetup luksClose /dev/mapper/rpiroot
