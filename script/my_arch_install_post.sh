echo ":: Running post-installation..."
echo ":: Discard unused packages weekly"
sudo systemctl enable paccache.timer
echo ":: Installing light-locker..."
sudo yes | pacman -S light-locker xfce4-power-manager --noconfirm
xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command --lock" --create -t string
echo ":: Installing blueman..."
sudo yes | pacman -S blueman --noconfirm
sudo systemctl enable bluetooth
sudo mv /root/90-blueman.rules /etc/polkit-1/rules.d/
echo ":: Enable dual boot with windows..."
sudo yes | pacman -S ntfs-3g --noconfirm
sudo mkdir /mnt/windows
sudo mount /dev/sda3 /mnt/windows
sudo yes | pacman -S os-prober --noconfirm
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo umount /mnt/windows
echo ":: Post-installation finished"
