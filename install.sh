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
cp configs/fstab /mnt/etc/fstab
#Setup glibc
#xchroot echo "LANG=en_US.UTF-8" > /etc/locale.conf; echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales; xbps-reconfigure -f glibc-locales 

#Install requirements on the encrypted system
xchroot /mnt xbps-install -Suvy cryptsetup dropbear dracut-crypt-ssh

#Setup boot options
echo "initramfs initrd.img followkernel" >> /mnt/boot/config.txt

#Add dropbear ssh setttings to dracut
cp configs/crypt-ssh.conf /mnt/etc/dracut.conf.d/
cp configs/05-custom.conf /mnt/etc/dracut.conf.d/

#Generate keys for authentication
xchroot umask 0077; mkdir /root/.dracut; ssh-keygen -t rsa -f /root/.dracut/ssh_dracut_rsa_key; ssh-keygen -t ecdsa -f /root/.dracut/ssh_dracut_ecdsa_key

#Give ssh keys to dropbear
xchroot touch /root/.dracut/authorized_keys; chmod 700 /root/.dracut/authorized_keys; cat /root/.dracut/ssh_dracut_rsa_key.pub >> /root/.dracut/authorized_keys; cat /root/.dracut/ssh_dracut_ecdsa_key.pub >> /root/.dracut/authorized_keys


#Generate initramfs
xchroot /mnt dracut /boot/initrd.img --force 6.6.69_2

cp configs/cmdline.txt /mnt/boot/cmdline.txt

#Unmount partitions
umount /mnt/boot
umount /mnt

#Close luks partition
cryptsetup luksClose /dev/mapper/rpiroot
