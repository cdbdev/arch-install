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
    First sector (34-1532901375, default = 1507735552) or {+-}size{KMGTP}:
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
Put server ‘Belgium’ on top in `/etc/pacman.d/mirrorlist`.
```
#  pacstrap /mnt base
#  cp wpa_supplicant.conf /mnt/var
#  genfstab -U /mnt >> /mnt/etc/fstab
#  arch-chroot /mnt
#  echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
#  ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime  
#  hwclock --systohc
```
Uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen and generate with:
```
#  locale-gen
#  echo "LANG=en_US.UTF-8" > /etc/locale.conf
#  echo "KEYMAP=be-latin1" > /etc/vconsole.conf
#  echo "myarch" > /etc/hostname
#  echo -e "127.0.0.1\tlocalhost" > /etc/hosts
#  echo -e "::1\t\tlocalhost" >> /etc/hosts
# passwd
#  useradd --create-home chris
#  passwd chris
#  pacman -S reflector
#  reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
#  pacman -S pacman-contrib sudo ufw wpa_supplicant vim acpi screenfetch
#  visudo  
#  gpasswd -a chris wheel
#  mv /var/wpa_supplicant.conf /etc/wpa_supplicant/
#  cp /etc/netctl/examples/wireless-wpa /etc/netctl/

```
