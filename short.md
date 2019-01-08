## Boot LIVE environment
Insert USB and start the system. Once you see some activity on the screen, press F12 a couple of times to make sure you enter the BOOT options screen. Then select the USB drive (USB HDD).

Select **Arch Linux archiso x86_64 UEFI CD** and press `e`.  
Add the following to the end of the line: `acpi_backlight=none  amdgpu.dc=0`.  
Press **Enter**.

## Prepare installation
```
#  loadkeys be-latin1
#  rfkill unblock all
#  ip link set wlp1s0 up
#  wpa_passphrase "SSID" "mykey" > wpa_supplicant.conf
#  wpa_supplicant -B -i wlp1s0 -c wpa_supplicant.conf
#  dhcpcd wlp1s0
#  ping www.google.be
#  timedatectl set-ntp true
#  gdisk /dev/sda
    Command (? for help): d
    Partition number (1-6): 4
    Command (? for help): d
    Partition number (1-6): 5
    Command (? for help): n
    Partition number (4-128, default 4):
    First sector (34-1532901375, default = 643708928) or {+-}size{KMGTP}:
    Last sector (643708928-1532901375, default = 1532901375) or {+-}size{KMGTP}: +412G
    Hex code or GUID (L to show codes, Enter = 8300):
    Partition number (5-128, default 5): 
    First sector (34-1532901375, default = 1507735552) or {+-}size{KMGTP}: +12G
    Last sector (1507735552-1532901375, default = 1532901375) or {+-}size{KMGTP}:
    Hex code or GUID (L to show codes, Enter = 8300): 8200
    Command (? for help): w
#  mkfs.ext4 /dev/sda<root partition>
#  mkswap /dev/sda<swap partition>
#  swapon /dev/sda<swap partition>
#  mount /dev/sda<root partition> /mnt
#  mkdir /mnt/efi
#  mount /dev/sda<efi partition> /mnt/efi
```

## Installation
```
#  vi /etc/pacman.d/mirrorlist		--> (put server 'Belgium' on top)
#  pacstrap /mnt base
#  cp wpa_supplicant.conf /mnt/var
#  genfstab -U /mnt >> /mnt/etc/fstab
#  arch-chroot /mnt
#  echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
#  ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime  
#  hwclock --systohc
#  vi /etc/locale.gen		--> (uncomment: "en_US.UTF-8 UTF-8")
#  locale-gen
#  echo "LANG=en_US.UTF-8" > /etc/locale.conf
#  echo "KEYMAP=be-latin1" > /etc/vconsole.conf
#  echo "myarch" > /etc/hostname
#  echo -e "127.0.0.1\tlocalhost" > /etc/hosts
#  echo -e "::1\t\tlocalhost" >> /etc/hosts
#  passwd
#  useradd --create-home chris
#  passwd chris
#  pacman -S reflector
#  reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
#  pacman -S pacman-contrib sudo ufw wpa_supplicant vim acpi 
#  visudo  
#  gpasswd -a chris wheel
#  mv /var/wpa_supplicant.conf /etc/wpa_supplicant/
#  cp /etc/netctl/examples/wireless-wpa /etc/netctl/
#  vi /etc/netctl/wireless-wpa		--> (edit/change to the following)
	Interface=wlp1s0  
	Security=wpa-config  
	WPAConfigFile='/etc/wpa_supplicant/wpa_supplicant.conf'  
#  vi /etc/wpa_supplicant/wpa_supplicant.conf		--> (add "ctrl_interface" to 1st line)
	ctrl_interface=/var/run/wpa_supplicant 
	network={
		ssid=”MYSSID”
		#psk=”passphrase”
		psk=???
	}  
#  netctl enable wireless-wpa
#  pacman -S grub efibootmgr
#  grub-install -–target=x86_64-efi –-efi-directory=/efi -–bootloader=arch  
#  vi /etc/default/grub		--> (change variable "GRUB_CMDLINE_LINUX_DEFAULT" to:)
	"quiet acpi_backlight=none amdgpu.dc=0"
#  grub-mkconfig -o /boot/grub/grub.cfg
#  pacman -S xorg-server
#  pacman -S xfce4 xfce4-goodies
#  pacman -S lightdm lightdm-gtk-greeter
#  vi /etc/lightdm/lightdm.conf		--> (change [Seat:*] section, like so:)
	[Seat:*]
	...
	greeter-session=lightdm-gtk-greeter
	...
#  systemctl enable lightdm.service
#  vi /etc/X11/xorg.conf.d/20-keyboard.conf
	Section "InputClass"
		Identifier "mykeyboard"
		MatchIsKeyboard "on"
		Option "XkbLayout" "be"
		Option "XkbVariant" "nodeadkeys"
	EndSection
#  pacman -S gvfs
#  pacman -S firefox ttf-dejavu arc-gtk-theme arc-icon-theme papirus-icon-theme pulseaudio screenfetch xreader libreoffice
#  exit
#  umount -R /mnt    
#  reboot
```

## Post installation
```
$  sudo systemctl enable paccache.timer
$  sudo pacman -S light-locker xfce4-power-manager
$  xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command --lock" --create -t string
$  vi /usr/bin/xflock4		--> (enable "light-locker-command -l")
	# Lock by xscreensaver or gnome-screensaver, if a respective daemon is running
	for lock_cmd in \
	    "light-locker-command -l" \
	    "xscreensaver-command -lock" \
	    "gnome-screensaver-command --lock"
	do
	    $lock_cmd >/dev/null 2>&1 && exit
	done
$  sudo pacman -S blueman
$  sudo systemctl enable bluetooth
$  vi /etc/polkit-1/rules.d/90-blueman.rules		--> (add the following)
	/* Allow users in wheel group to use blueman feature requiring root without authentication */
	polkit.addRule(function(action, subject) {
	    if ((action.id == "org.blueman.network.setup" ||
		 action.id == "org.blueman.dhcp.client" ||
		 action.id == "org.blueman.rfkill.setstate" ||
		 action.id == "org.blueman.pppd.pppconnect") &&
		subject.isInGroup("wheel")) {

		return polkit.Result.YES;
	    }
	});
$  sudo pacman -S ntfs-3g
$  sudo mkdir /mnt/windows
$  sudo mount /dev/sda<windows partition number> /mnt/windows
$  sudo pacman -S os-prober
$  sudo os-prober
$  sudo grub-mkconfig -o /boot/grub/grub.cfg
$  sudo umount /mnt/windows
```
## Troubleshooting
_**wpa_passphrase**_:  
Make sure you don't type mistakes during the entering of the command, otherwise strange characters could jump in.  
In case of errors, run `wpa_supplicant` without `-B` option.

_**Error: could not set interface 'p2p ...' up**_:  
```
#  killall wpa_supplicant dhcpcd
#  wpa_supplicant -B -i wlp1s0 -c /etc/wpa_supplicant/wpa_supplicant.conf
```

_**No grub menu at boot**_:  
Enter the following commands (considering '4' is the correct partition number of root installation, otherwise check with command ‘**ls**’):  
```
#  grub rescue> set prefix=(hd0,4)/boot/grub
#  grub rescue> insmod normal
#  grub rescue> normal
```

Reinstall grub when booted in Arch.

_**No wireless with netctl**_:  
```
#  rfkill unblock all
#  reboot
```

_**Screen too dark**_:  
```
#  cd /sys/class/backlight/amdgpu_bl0
#  tee brightness <<< 150
```
