#!/bin/bash

# ----------------------------------------------------------------------- #
# Arch Linux POST install script						                              #
# ----------------------------------------------------------------------- #
# Author    : Chris							                                          #
# Project   : https://github.com/cdbdev/arch-install			                #
# Reference : https://wiki.archlinux.org/index.php/Installation_guide	    #
# ----------------------------------------------------------------------- #


echo ":: Running post-installation..."

# ----------------------------------------------- 
# Add screenfetch
# ----------------------------------------------- 

echo ":: Adding screenfetch..."
echo screenfetch >> .bashrc

# ----------------------------------------------- 
# Disable XFCE buttons on shutdown
# ----------------------------------------------- 
echo ":: Disable buttons on shutdown..."
xfconf-query -c xfce4-session -np '/shutdown/ShowSuspend' -t 'bool' -s 'false'
xfconf-query -c xfce4-session -np '/shutdown/ShowHibernate' -t 'bool' -s 'false'

# ----------------------------------------------- 
# Discard unused packages weekly
# ----------------------------------------------- 
echo ":: Discard unused packages weekly"
sudo systemctl enable paccache.timer

# ----------------------------------------------- 
# Install light locker
# ----------------------------------------------- 
echo ":: Installing light-locker..."
yes | sudo pacman -S light-locker xfce4-power-manager --noconfirm
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command --lock" --create -t string

# ----------------------------------------------- 
# Install bluetooth package and add config
# ----------------------------------------------- 
echo ":: Installing blueman..."
yes | sudo pacman -S blueman --noconfirm
sudo systemctl enable bluetooth
sudo mv /home/"$USER"/90-blueman.rules /etc/polkit-1/rules.d/

# ----------------------------------------------- 
# Enable dual boot with windows
# ----------------------------------------------- 
echo ":: Enable dual boot with windows..."
yes | sudo pacman -S ntfs-3g --noconfirm
sudo mkdir /mnt/windows
sudo mount /dev/sda3 /mnt/windows
yes | sudo pacman -S os-prober --noconfirm
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo umount /mnt/windows

echo ":: Post-installation finished"
