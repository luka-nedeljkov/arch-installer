#!/bin/bash

# Source config and fail on error
echo "Loading config"
source arch-install.conf
set -e

# Set time
#timedatelctl set-ntp true

# Choose drive
read -rp "Are you installing in a virtual machine? [y/N] " choice
case "$choice" in
[yY])
	DRIVE=$VM_DRIVE
	ESP=$VM_ESP
	SWAP=$VM_SWAP
	ROOT=$VM_ROOT
	HOME=$VM_HOME
	;;
*)
	DRIVE=$NVME_DRIVE
	ESP=$NVME_ESP
	SWAP=$NVME_SWAP
	ROOT=$NVME_ROOT
	HOME=$NVME_HOME
	;;
esac
sleep 3s
clear

# Zap and partition drives
echo "Start partitioning"
read -rp "RAM size(GB): " RAMSIZE
sgdisk -Z $DRIVE
sgdisk -n 0:0:+1G -t 0:ef00 -c 0:"esp" $DRIVE
sgdisk -n 0:0:+${RAMSIZE}G -t 0:8200 -c 0:"swap" $DRIVE
sgdisk -n 0:0:+48G -t 0:8300 -c 0:"root" $DRIVE
sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" $DRIVE

# Format partitions
echo "Start partition formatting"
mkfs.fat -n esp -F32 $ESP
mkfs.ext4 $ROOT
mkfs.ext4 $HOME
mkswap $SWAP

# Mount partitions
echo "Mounting partitions"
mount $ROOT /mnt
mount $ESP /mnt/boot --mkdir
mount $HOME /mnt/home --mkdir
swapon $SWAP
sleep 3s
clear

# Install base system
echo "Installing base system"
pacstrap -K /mnt amd-ucode base base-devel git linux linux-firmware linux-headers neovim openssh zsh
sleep 3s
clear

# Congifure /mnt/etc/fstab
echo "Generating fstab"
genfstab -U /mnt >>/mnt/etc/fstab
sed -i 's/fmask=0022/fmask=0137/' /mnt/etc/fstab
sed -i 's/dmask=0022/dmask=0027/' /mnt/etc/fstab
sleep 3s
clear

# Prepare chroot
echo "Preparing for chroot"
cp arch-install.conf /mnt/arch-install.conf
cp chroot-install.sh /mnt/chroot-install.sh
chmod +x /mnt/chroot-install.sh
arch-chroot /mnt ./chroot-install.sh
sleep 3s
clear

# Unmount and reboot
echo "Unmounting all drives"
umount -R /mnt

# Reboot
echo "Installation complete!"
echo "Rebooting in 10s"
sleep 10s
reboot
