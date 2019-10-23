#!/bin/bash

# ----------------------------------------------------------------------- #
# Arch Linux install script						  #
# ----------------------------------------------------------------------- #
# Author    : Chris							  #
# Project   : https://github.com/cdbdev/arch-install			  #
# Reference : https://wiki.archlinux.org/index.php/Installation_guide	  #
# ----------------------------------------------------------------------- #


# ----------------------------------------------- 
# Initial setup ( wireless, time/date )
# ----------------------------------------------- 

echo ":: Disabling soft blocks..."
rfkill unblock all

# Ask password for root
while true; do
	echo -n ">> Please enter root password: "
	read -s root_pass
	echo

	echo -n ">> Root password (confirm): "
	read -s root_pass_cnf
	echo

	[ "$root_pass" = "$root_pass_cnf" ] && break || echo "Passwords don't match, try again."
done
echo

# Ask credentials for new user
echo -n ">> Please enter a name for the new user: "
read new_user

while true; do
	echo -n ">> Please enter a password for new user: "
	read -s new_user_pass
	echo

	echo -n ">> New user password (confirm): "
	read -s new_user_pass_cnf
	echo

	[ "$new_user_pass" = "$new_user_pass_cnf" ] && break || echo "Passwords don't match, try again."
done
echo

# Ask interface name and enable it
ip link show
echo -n ">> Please enter wifi interface name [wlp1s0,...]: "
read wifi_int

ip link set "$wifi_int" up

# Ask wifi SSID + WPA Key and try to connect
echo -n ">> Please enter SSID: "
read ssid

echo -n ">> Please enter WPA key: "
read wpa_key

wpa_passphrase "$ssid" "$wpa_key" > wpa_supplicant-"$wifi_int".conf
wpa_supplicant -B -i "$wifi_int" -c wpa_supplicant-"$wifi_int".conf

dhcpcd "$wifi_int"

# Check internet connection
if ping -q -c 1 -W 1 google.com >/dev/null; then
	echo ":: Internet up and running!"
else
    echo ":: Please check your internet connection! Installation aborted."
    exit 1
fi

timedatectl set-ntp true


# -----------------------------------------
# Start Gdisk for partitioning of the disks 
# -----------------------------------------

echo ":: Starting gdisk..."
(
echo d # remove partition
echo 4 # partition 4 removal
echo d # remove partition
echo 5 # partition 5 removal
echo n # new partition
echo 4 # partition number 4
echo   # default, start immediately after preceding partition
echo +412G # + 412 GB linux partition
echo 8300 # partition type linux
echo n # new partition
echo 5 # partition number 5
echo   # default, start immediately after preceding partition
echo +12G # + 12 GB linux swap partition
echo 8200 # partition type swap
echo p # print in-memory partition table
echo w # save changes
echo y # confirm changes
) | gdisk /dev/sda


# ----------------------------------------------------------------- 
# Format partitions (one partition for system + partition for swap) 
# ----------------------------------------------------------------- 
yes | mkfs.ext4 /dev/sda4
mkswap /dev/sda5
swapon /dev/sda5


# ---------------------
# Mount the file system
# ---------------------
mount /dev/sda4 /mnt


# -----------------
# Arch installation
# -----------------

# Rank mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl "https://www.archlinux.org/mirrorlist/?country=BE&country=NL&country=DE&country=FR&country=US&protocol=http&protocol=https" > /etc/pacman.d/mirrorlist
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist

# Install base + kernel(linux)
pacstrap /mnt base linux linux-firmware


# --------------------
# Configure the system
# --------------------

# genfstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy necessary files to new system
cp my_arch_install_post.sh /mnt/root/
cp /etc/pacman.d/mirrorlist /mnt/root/
cp wpa_supplicant-"$wifi_int".conf /mnt/root/
cp -r conf/. /mnt/root/

# -----------------------------------------
# Mount efi partition for GRUB installation
# -----------------------------------------
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi

# --------
# Chroot
# --------
echo ":: Change root into the new system"
arch-chroot /mnt /bin/bash <<EOF

# 1 Disable <beep>
echo ":: Disabling <beep>"
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# 2 Time zone
echo ":: Setup time zone"
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc

# 3 Localization
echo ":: Setup Localization"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=be-latin1" > /etc/vconsole.conf

# 4 Network configuration
echo "myarch" > /etc/hostname
echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "::1\t\tlocalhost" >> /etc/hosts

# 5 Set root password
echo ":: Setting password for root"
echo "root:${root_pass}" | chpasswd

# 6 Setup new user
echo -n ">> Setup new user"
useradd --create-home "$new_user"
echo "${new_user}:${new_user_pass}" | chpasswd
mv /root/my_arch_install_post.sh /home/"$new_user"/

# 7 Update mirrorlist
echo ":: Updating mirrorlist..."
#yes | pacman -S reflector --noconfirm
#reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
mv /root/mirrorlist /etc/pacman.d/mirrorlist

# 8 Install user specific packages
echo ":: Installing user specific packages..."
yes | pacman -S xf86-video-amdgpu dhcpcd e2fsprogs vi amd-ucode pacman-contrib sudo nftables wpa_supplicant vim acpi pulseaudio blueman wget which dosfstools ntfs-3g os-prober --noconfirm
# 8.1 Setup nftables
mv /root/nftables.conf /etc/
systemctl enable nftables.service

# 9 Change permissions for new user
echo ":: Change permissions for new user"
echo "$new_user ALL=(ALL:ALL) ALL" | EDITOR='tee -a' visudo
echo ":: Adding user to group 'wheel'..."
gpasswd -a "$new_user" wheel 

# 10 Enable wifi at boot
echo ":: Enabling WIFI at boot..."
mv /root/wpa_supplicant-"$wifi_int".conf /etc/wpa_supplicant/
# 10.1 Add 'ctrl_interface=/var/run/wpa_supplicant' to 1st line of 'wpa_supplicant.conf'
sed -i '1 i\ctrl_interface=/var/run/wpa_supplicant\n' /etc/wpa_supplicant/wpa_supplicant-"$wifi_int".conf
systemctl enable wpa_supplicant@"$wifi_int"
# systemctl enable dhcpcd@"$wifi_int"
systemctl enable dhcpcd.service
# 10.2 Do not wait at startup for dhcpcd
mkdir /etc/systemd/system/dhcpcd@.service.d
echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/dhcpcd -b -q %I" > /etc/systemd/system/dhcpcd@.service.d/no-wait.conf

# 11  Install and prepare XFCE
yes | pacman -S xorg-server --noconfirm
yes | pacman -S xfce4 xfce4-goodies xfce4-power-manager thunar-volman catfish xfce4-session --noconfirm
yes | pacman -S lightdm lightdm-gtk-greeter light-locker --noconfirm
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
mv /root/20-keyboard.conf /etc/X11/xorg.conf.d/ 
yes | pacman -S firefox ttf-dejavu arc-gtk-theme moka-icon-theme screenfetch xreader libreoffice galculator gvfs conky --noconfirm
mv /root/90-blueman.rules /etc/polkit-1/rules.d/

# 12 Install and configure grub
yes | pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader=arch
# 12.1 Fix dark screen, hibernate & screen tearing (add 'acpi_backlight=none amdgpu.dc=0')
#sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"quiet acpi_backlight=none amdgpu.dc=0\"' /etc/default/grub
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

# 13  Add screenfetch
echo screenfetch >> /home/"$new_user"/.bashrc

# 14  Discard unused packages weekly
systemctl enable paccache.timer

# 15  Enable bluetooth
systemctl enable bluetooth

# 16. Disable acpi backlight (amdgpu backlight is already used)
systemctl mask systemd-backlight@backlight:acpi_video0.service

echo ":: Exit chroot..."
EOF


# ------
# Reboot
# ------
echo ":: Installation finished." 
echo ":: You can unmount [umount -R /mnt] and reboot now [reboot], or remain in the system."
