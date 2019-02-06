#!/bin/bash

# ----------------------------------------------------------------------- #
# Arch Linux install script						  #
# ----------------------------------------------------------------------- #
# Author    : Chris							  #
# Project   : https://github.com/cdbdev/arch-install			  #
# Reference : https://wiki.archlinux.org/index.php/Installation_guide	  #
# ----------------------------------------------------------------------- #


# ----------------------------------------------- 
# Initial setup ( keyboard, wireless, time/date )
# ----------------------------------------------- 

echo ":: Loading BE keyboard..."
loadkeys be-latin1

echo ":: Disabling soft blocks..."
rfkill unblock all

# Ask password for root
echo -n ">> Please enter a password for 'root' user: "
read -s root_pass
echo

# Ask credentials for new user
echo -n ">> Please enter a name for the new user: "
read new_user
echo -n ">> Please enter a password for new user: "
read -s new_user_pass
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

wpa_passphrase "$ssid" "$wpa_key" > wpa_supplicant.conf
wpa_supplicant -B -i "$wifi_int" -c wpa_supplicant.conf

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


# ----------------------
# Mount the file systems
# ----------------------
mount /dev/sda4 /mnt
mkdir /mnt/efi
mount /dev/sda1 /mnt/efi


# -----------------
# Arch installation
# -----------------

# Rank mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl "https://www.archlinux.org/mirrorlist/?country=BE&country=NL&country=DE&country=FR&protocol=http&protocol=https" > /etc/pacman.d/mirrorlist
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist

# Install base
pacstrap /mnt base


# --------------------
# Configure the system
# --------------------

# genfstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy necessary files to new system
cp my_arch_install_post_budgie.sh /mnt/root/
cp -r conf/. /mnt/root/

# Chroot
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
mv /root/my_arch_install_post_budgie.sh /home/"$new_user"/

# 7 Retrieve latest mirrors and update mirrorlist
echo ":: Updating mirrorlist..."
yes | pacman -S reflector --noconfirm
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# 8 Install user specific packages
echo ":: Installing user specific packages..."
yes | pacman -S pacman-contrib sudo nftables wpa_supplicant vim acpi --noconfirm
# 8.1 Setup nftables
mv /root/nftables.conf /etc/
systemctl enable nftables.service

# 9 Change permissions for new user
echo ":: Change permissions for new user"
echo "$new_user ALL=(ALL:ALL) ALL" | EDITOR='tee -a' visudo
echo ":: Adding user to group 'wheel'..."
gpasswd -a "$new_user" wheel 

# 10 Enable wifi at boot with netctl
#echo ":: Enabling WIFI at boot..."
#mv /root/wpa_supplicant.conf /etc/wpa_supplicant/
#mv /root/wireless-wpa /etc/netctl/
# 10.1 Add 'ctrl_interface=/var/run/wpa_supplicant' to 1st line of 'wpa_supplicant.conf'
#sed -i '1 i\ctrl_interface=/var/run/wpa_supplicant\n' /etc/wpa_supplicant/wpa_supplicant.conf
#netctl enable wireless-wpa

# 11 Install and configure grub
yes | pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader=arch
# 11.1 Fix dark screen & hibernate (add 'acpi_backlight=none amdgpu.dc=0')
sed -i 's/\"quiet/\"quiet acpi_backlight=none amdgpu.dc=0/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


# 12  Install and prepare BUDGIE
yes | pacman -S xorg-server --noconfirm
yes | pacman -S budgie-desktop --noconfirm 
yes | pacman -S lightdm lightdm-gtk-greeter --noconfirm
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
yes | pacman -S nautilus gnome-control-center gnome-settings-daemon gnome-terminal gnome-screensaver gnome-backgrounds firefox gedit gnome-calculator eog evince gnome-mpv networkmanager gnome-keyring --noconfirm
mv /root/20-keyboard.conf /etc/X11/xorg.conf.d/ 


echo ":: Exit chroot..."
EOF


# ------
# Reboot
# ------
umount -R /mnt
reboot