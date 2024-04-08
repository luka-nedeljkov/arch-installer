# Source config
echo "Loading config"
source /arch-install.conf

# Remount esp
echo "Remounting ESP"
umount /boot
mount /boot

# Configure pacman
echo "Configuring and refreshing pacman"
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i '/ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
sed -i 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '/\[multilib\]/{n;s_.*_Include = /etc/pacman.d/mirrorlist_}' /etc/pacman.conf
pacman -Syyuu
sleep 3s
clear

# Locale
echo "Generating locale"
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# Timezone
echo "Setting timezone"
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc
sleep 3s
clear

# Enable fstrim
echo "Enabling fstrim.timer systemd service"
systemctl enable fstrim.timer

# Network
echo "Configuring network"
read -rp "Hostname: " hostname
echo $hostname >/etc/hostname
pacman -Syu networkmanager
systemctl enable NetworkManager
systemctl enable systemd-resolved

# Root password
echo "Change root password"
passwd root
sleep 3s
clear

# Bootloader
echo "Installing bootloader"
bootctl install

echo "default arch.conf" >/boot/loader/loader.conf
echo "timeout 0" >>/boot/loader/loader.conf
echo "editor no" >>/boot/loader/loader.conf

echo -e "title\tArch Linux" >/boot/loader/entries/arch.conf
echo -e "linux\t/vmlinuz-linux" >>/boot/loader/entries/arch.conf
echo -e "initrd\t/amd-ucode.img" >>/boot/loader/entries/arch.conf
echo -e "initrd\t/initramfs-linux.img" >>/boot/loader/entries/arch.conf
echo -e "options root=PARTUUID=$(blkid -s PARTUUID -o value $ROOT) rw" >>/boot/loader/entries/arch.conf
sleep 3s
clear

# Add user
echo "Adding user"
useradd -m -G wheel -s /bin/zsh $LUKAUSER
passwd luka
chfn -f Luka luka

echo "Adding user to sudoers"
echo -e "\n" | sudo EDITOR="tee -a" visudo
echo "%wheel ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
echo -e "\n" | sudo EDITOR="tee -a" visudo
echo "Defaults rootpw" | sudo EDITOR="tee -a" visudo

# Remove script and exit chroot
echo "Removing script and exiting chroot"
rm /arch-install.conf
rm /chroot-install.sh
sleep 3s
exit
