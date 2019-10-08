#!/bin/bash

# ----------------------------------------------------------------------- #
# Arch Linux POST install script
# ----------------------------------------------------------------------- #
# Author    : Chris	
# Project   : https://github.com/cdbdev/arch-install
# Reference : https://wiki.archlinux.org/index.php/Installation_guide	
# ----------------------------------------------------------------------- #


echo ":: Running post-installation..."

# ----------------------------------------------- 
# Disable XFCE buttons on shutdown
# ----------------------------------------------- 
echo ":: Disable buttons on shutdown..."
xfconf-query -c xfce4-session -np '/shutdown/ShowSuspend' -t 'bool' -s 'false'
xfconf-query -c xfce4-session -np '/shutdown/ShowHibernate' -t 'bool' -s 'false'

# ----------------------------------------------- 
# Install light locker
# ----------------------------------------------- 
echo ":: Enabling light-locker..."
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command --lock" --create -t string

echo ":: Post-installation finished"
