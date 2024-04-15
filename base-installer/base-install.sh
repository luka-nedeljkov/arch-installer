#!/bin/bash

# Source config and fail on error
echo "Loading config"
source base-install.conf
set -e

# Set time
#timedatelctl set-ntp true

# Detect VM and define drives
if cat /proc/cpuinfo | grep -q "hypervisor"; then
	DRIVE=$VM_DRIVE
	ESP=$VM_ESP
	SWAP=$VM_SWAP
	ROOT=$VM_ROOT
	HOME=$VM_HOME
else
	DRIVE=$NVME_DRIVE
	ESP=$NVME_ESP
	SWAP=$NVME_SWAP
	ROOT=$NVME_ROOT
	HOME=$NVME_HOME
fi

# Zap and partition drives
echo "Setting up partitions"
sgdisk -Z $DRIVE
sgdisk -n 0:0:+1G -t 0:ef00 -c 0:"esp" $DRIVE
sgdisk -n 0:0:+${SWAP_SIZE}G -t 0:8200 -c 0:"swap" $DRIVE
sgdisk -n 0:0:+48G -t 0:8300 -c 0:"root" $DRIVE
sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" $DRIVE

# Format partitions
mkfs.fat -F32 $ESP
mkfs.ext4 -F $ROOT
mkfs.ext4 -F $HOME
mkswap $SWAP

# Mount partitions
mount $ROOT /mnt
mount $ESP /mnt/boot --mkdir
mount $HOME /mnt/home --mkdir
swapon $SWAP
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Install base system
pacstrap -K /mnt amd-ucode base base-devel linux linux-firmware linux-headers

# Congifure /mnt/etc/fstab
echo "Generating fstab"
genfstab -U /mnt >>/mnt/etc/fstab
sed -i 's/fmask=0022/fmask=0137/' /mnt/etc/fstab
sed -i 's/dmask=0022/dmask=0027/' /mnt/etc/fstab
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Prepare chroot
cp base-install.conf /mnt/base-install.conf
cp chroot-install.sh /mnt/chroot-install.sh
#chmod +x /mnt/chroot-install.sh
arch-chroot /mnt ./chroot-install.sh

# Unmount and reboot
echo "Unmounting all drives"
rm /mnt/base-install.conf
rm /mnt/chroot-install.sh
git clone https://github.com/luka-nedeljkov/arch-scripts /mnt/home/$USER/arch-scripts
umount -R /mnt

# Reboot
echo "Installation complete!"

read -rsp "Press enter to reboot..."
#echo "Rebooting in 5s"
#sleep 5s
reboot
