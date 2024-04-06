# Source config
source arch-install.conf

# Remount esp
umount /boot
mount /boot

# Configure pacman
sed 's/#Color/Color/' /etc/pacman.conf
sed 's/#ParallelDownloads=5/ParallelDownloads=5/' /etc/pacman.conf
sed 's/#ILoveCandy/ILoveCandy/' /etc/pacman.conf
sed 's/#[multilib]/[multilib]/' /etc/pacman.conf
sed '/[multilib]/{n; s_#Include = /etc/pacman.d/mirrorlist_Include = /etc/pacman.d/mirrorlist_}' /etc/pacman.conf
pacman -Syyuu

# Locale
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# Timezone
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc

# Enable fstrim
systemctl enable fstrim.timer

# Network
read -rp "Hostname: " hostname
echo $hostname >/etc/hostname
pacman -Syu networkmanager
systemctl enable NetworkManager
systemctl enable systemd-resolved

# Root password
passwd root

# Bootloader
bootctl install

echo "default arch.conf" > /boot/loader/loader.conf
echo "timeout 0" >> /boot/loader/loader.conf
echo "editor no" >> /boot/loader/loader.conf

echo "title\tArch Linux" > /boot/loader/entries/arch.conf
echo "linux\t/vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd\t/amd-ucode.img" >> /boot/loader/entries/arch.conf
echo "initrd\t/initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $ROOT) rw" >> /boot/loader/entries/arch.conf

# Add user
useradd -m -G wheel -s /bin/zsh $LUKAUSER
passwd luka
chfn luka

echo "\n" | sudo EDITOR="tee -a" visudo
echo "%wheel ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
echo "\n" | sudo EDITOR="tee -a" visudo
echo "Defaults rootpw" | sudo EDITOR="tee -a" visudo

# Remove script and exit chroot
rm /arch-install.conf
rm /chroot-install.sh
exit
