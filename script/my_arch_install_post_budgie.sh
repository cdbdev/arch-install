echo ":: Running post-installation..."
echo ":: Discard unused packages weekly"
sudo systemctl enable paccache.timer
echo ":: Enable bluetooth..."
sudo systemctl enable bluetooth
echo ":: Enable dual boot with windows..."
yes | sudo pacman -S ntfs-3g --noconfirm
sudo mkdir /mnt/windows
sudo mount /dev/sda3 /mnt/windows
yes | sudo pacman -S os-prober --noconfirm
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo umount /mnt/windows
echo ":: Post-installation finished"
