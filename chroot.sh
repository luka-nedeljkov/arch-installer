findroot() {
	for i in "${partitions[@]}"; do
		IFS='|' read -ra array <<<"$i"
		if [[ "${array[4]}" = "/mnt" ]]; then
			echo "${array[0]}"
		fi
	done
}

# Source config
source ./arch-installer.conf

# Configure pacman and install additional packages
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = ${paralleldownloads}/" /etc/pacman.conf
if [[ "$ilovecandy" = true ]]; then
	sed -i '/ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
fi
sed -i 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '/\[multilib\]/{n;s_.*_Include = /etc/pacman.d/mirrorlist_}' /etc/pacman.conf
pacman -Sy --needed --noconfirm $packages
read
#sleep 1s
#clear

# Locale
echo "$locale" >> /etc/locale.gen
locale-gen
echo "LANG=$keymap" > /etc/locale.conf

# Timezone
echo "Setting timezone"
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Enable fstrim
if [[ "$fstrim" = true ]]; then
	echo "Enabling fstrim.timer service"
	systemctl enable fstrim.timer
fi

# Network
echo "Configuring network"
echo $hostname > /etc/hostname
systemctl enable NetworkManager
systemctl enable systemd-resolved

# Root password
echo "Root password"
passwd root

# Bootloader
grub-install --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Add user
echo "Adding user: $user"
useradd -m -G wheel $user
passwd $user
chfn -f $(echo $user | sed 's/.*/\u&/') $user

# Sudoers settings
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$user
echo "Defaults rootpw" >> /etc/sudoers.d/$user

read

# Exit chroot
exit
