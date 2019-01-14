#!/bin/bash

# ----------------------------------------------------------------------- #
# Arch Linux install script						  #
# ----------------------------------------------------------------------- #
# Author    : Chris							  #
# Project   : https://github.com/cdbdev/arch-install			  #
# Reference : https://wiki.archlinux.org/index.php/Installation_guide	  #
# ----------------------------------------------------------------------- #


# Initial setup ( keyboard, wireless, time/date )
# ----------------------------------------------- 

echo "Loading BE keyboard..."
loadkeys be-latin1

echo "Disabling soft blocks..."
rfkill unblock all

# Ask interface name and enable it
ip link show
echo ":: Please enter wifi interface name [wlp1s0,...]"
read wifi_int

ip link set "$wifi_int" up

# Ask wifi SSID + WPA Key and try to connect
echo ":: Please enter SSID"
read ssid

echo ":: Please enter WPA key"
read wpa_key

wpa_passphrase "$SSID" "$wpa_key" > wpa_supplicant.conf
wpa_supplicant -B -i "$wifi_int" -c wpa_supplicant.conf

dhcpcd "$wifi_int"

# Check internet connection
if ping -q -c 1 -W 1 google.com >/dev/null; then
	echo "Internet up and running!"
else
    echo "Please check your internet connection! Installation aborted."
    exit 1
fi

timedatectl set-ntp true


# Start Gdisk for partitioning of the disks 
# -----------------------------------------

echo "Starting gdisk..."
sgdisk /dev/sda -p
sgdisk /dev/sda -d=4
sgdisk /dev/sda -d=5
sgdisk /dev/sda -n=4:0:+412G -t=4:8300
sgdisk /dev/sda -n=5:0:+12G -t=5:8200


# Format partitions (one partition for system + partition for swap) 
# ----------------------------------------------------------------- 
mkfs.ext4 /dev/sda4
mkswap /dev/sda5
swapon /dev/sda5


# Mount the file systems
# ----------------------
mount /dev/sda4 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi


# Arch installation
# -----------------

# Put server 'Belgium' on top in : /etc/pacman.d/mirrorlist
echo "Put mirror servers of 'Belgium' on top in the following file"
echo ":: Please press <Enter> to edit /etc/pacman.d/mirrorlist"
read press_enter
vi /etc/pacman.d/mirrorlist

# Install base
pacstrap /mnt base


# Configure the system
# --------------------

# genfstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy 'wpa_supplicant' to new system
cp wpa_supplicant.conf /mnt/var
cp conf/* /mnt/var

# Chroot
echo "Change root into the new system"
arch-chroot /mnt

# 1 Disable <beep>
echo "Disabling <beep>"
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# 2 Time zone
echo "Setup time zone"
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc

# 3 Localization
echo "Setup Localization"
# 3.1 uncomment 'en_US.UTF-8 UTF-8'
sed -i '/#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=be-latin1" > /etc/vconsole.conf

# 4 Network configuration
echo "myarch" > /etc/hostname
echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "::1\t\tlocalhost" >> /etc/hosts

# 5 Set root password
echo ":: Set password for root"
passwd

# 6 Setup new user
echo ":: Please enter new username"
read new_user
useradd --create-home "$new_user"
echo ":: Please set password for new user"
passwd chris

# 7 Retrieve latest mirrors and update mirrorlist
echo "Updating mirrorlist..."
pacman -S reflector
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# 8 Install user specific packages
echo "Installing user specific packages..."
pacman -S pacman-contrib sudo ufw wpa_supplicant vim acpi

# 9 Change permissions for new user
echo "Change permissions for new user"
echo ":: Please press <Enter> to edit sudo"
read press_enter
visudo
echo "Adding user to group 'wheel'..."
gpasswd -a chris wheel 

# 10 Enable wifi at boot with netctl
echo "Enabling WIFI at boot..."
mv /var/wpa_supplicant.conf /etc/wpa_supplicant/
mv /var/wireless-wpa /etc/netctl
# 10.1 Add 'ctrl_interface=/var/run/wpa_supplicant' to 1st line of 'wpa_supplicant.conf'
sed -i '1 i\ctrl_interface=/var/run/wpa_supplicant\n' /etc/wpa_supplicant/wpa_supplicant.conf
netctl enable wireless-wpa

# 11 Install and configure grub
pacman -S grub efibootmgr
grub-install -–target=x86_64-efi –-efi-directory=/efi -–bootloader=arch
# 11.1 Fix dark screen & hibernate (add 'acpi_backlight=none amdgpu.dc=0')
sed -i 's/\"quiet/\"quiet acpi_backlight=none amdgpu.dc=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "Exit chroot..."
exit


# Reboot
# ------
umount -R /mnt
reboot
