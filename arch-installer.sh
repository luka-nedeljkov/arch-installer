#!/bin/bash

findroot() {
	for i in "${partitions[@]}"; do
		IFS='|' read -ra array <<< "$i"
		if [[ "${array[4]}" == "/mnt" ]]; then
			echo "${array[0]}"
		fi
	done
}

# Source config and fail on error
echo "Loading config"
source arch-installer.conf
set -e

# Partition drives and format partitions
echo "Setting up partitions"
if [[ "$zap" = true ]]; then
	sgdisk -Z $drive
fi
for i in "${partitions[@]}"; do
	IFS='|' read -ra array <<< "$i"
	if [[ ${array[5]} = "no" ]]; then
		continue
	fi
	sgdisk -n 0:0:${array[1]} -t 0:${array[2]} -c 0:${array[3]} $drive
	case ${array[2]} in
	"ef00" | "ea00")
		mkfs.fat -F 32 ${array[0]}
		;;
	"8200")
		mkswap ${array[0]}
		;;
	"8300")
 		[[ $filesystem = "btrfs" ]] && mkfs.btrfs -f ${array[0]}
		[[ $filesystem = "ext4" ]] && mkfs.ext4 -F ${array[0]}
		;;
	esac
done

# Mount Btrfs
if [[ $filesystem = "btrfs" ]]; then
    mount $(findroot) /mnt
    for i in "${subvolumes[@]}"; do
        IFS='|' read -ra array <<< "$i"
        btrfs subvolume create /mnt/${array[0]}
    done
    umount /mnt
    
    for i in "${subvolumes[@]}"; do
        IFS='|' read -ra array <<< "$i"
        mount -o noatime,compress=zstd,subvol=${array[0]} $(findroot) ${array[1]} --mkdir
    done
    
    IFS='|' read -ra esp <<< ${partitions[0]}
    mount -o umask=0077 ${esp[0]} ${esp[4]} --mkdir
    IFS='|' read -ra swap <<< ${partitions[1]}
    swapon ${swap[0]}
fi

# Mount Ext4
if [[ $filesystem = "ext4" ]]; then
	mount $(findroot) /mnt
	for i in "${partitions[@]}"; do
		IFS='|' read -ra array <<<"$i"
		if [[ "${array[4]}" != "/mnt" ]]; then
			if [[ "${array[4]}" = "swap" ]]; then
				swapon ${array[0]}
			elif [[ "${array[4]}" = "/mnt/efi" ]]; then
				mount ${array[0]} ${array[4]} --mkdir -o umask=0077
			else
				mount ${array[0]} ${array[4]} --mkdir
			fi
		fi
	done
fi
sleep 1s
clear

# Install base system
pacstrap -K /mnt ${cpu}-ucode base base-devel linux linux-firmware
sleep 1s
clear

# Congifure /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Prepare chroot
cp arch-installer.conf /mnt/arch-installer.conf
cp chroot.sh /mnt/chroot.sh
arch-chroot /mnt ./chroot.sh

# Unmount and reboot
echo "Unmounting all drives"
rm /mnt/arch-installer.conf
rm /mnt/chroot.sh
umount -R /mnt
swapoff -a

# Reboot
echo "Installation complete!"
echo "Rebooting in 5s"
sleep 5s
reboot
