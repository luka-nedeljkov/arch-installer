#!/bin/bash

# Source config and fail on error
source arch-install.conf
set -e

# Update pacman
pacman -Syyuu

# Set time
#timedatelctl set-ntp true

# Zap and partition drives
read -rp "RAM size: " RAMSIZE
sgdisk -Z $DRIVE
sgdisk -n 0:0:+1G -t 0:ef00 -c 0:"esp" $DRIVE
sgdisk -n 0:0:+${RAMSIZE}G -t 0:8200 -c 0:"swap" $DRIVE
sgdisk -n 0:0:+48G -t 0:8300 -c 0:"root" $DRIVE
sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" $DRIVE

# Format partitions
mkfs.fat -n esp -F32 $ESP
mkfs.ext4 $ROOT
mkfs.ext4 $HOME
mkswap $SWAP

# Mount partitions
mount $ROOT /mnt
mount $ESP /mnt/boot --mkdir
mount $HOME /mnt/home --mkdir
swapon $SWAP

# Install base system
pacstrap -K /mnt amd-ucode base base-devel git linux linux-firmware linux-headers neovim openssh zsh

# Congifure /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
sed 's/fmask=0022/fmask=0137/' /mnt/etc/fstab
sed 's/dmask=0022/dmask=0027/' /mnt/etc/fstab

# Prepare chroot
cp arch-install.conf /mnt/arch-install.conf
cp chroot-install.sh /mnt/chroot-install.sh
chmod +x /mnt/chroot-install.sh
arch-chroot /mnt ./chroot-install.sh

# Unmount and reboot
umount -R /mnt
reboot
