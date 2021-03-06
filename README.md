# Installation guide
This guide documents the specific steps needed to install Arch Linux on my Lenovo ideapad 320.  

Download this repo with:  
`wget --no-check-certificate https://github.com/cdbdev/arch-install/archive/master.tar.gz`

## Installation media
Download an installation image from https://www.archlinux.org/download/ and create the installation media:

In **GNU/Linux**:
Run the following commands, replacing /dev/sdx with your drive, e.g. /dev/sdb. (Do not append a partition number, so do not use something like /dev/sdb1):

```
#  mkfs.vfat -I /dev/sdx
#  dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx status=progress oflag=sync
```

In **Windows**:

Using Rufus from https://rufus.akeo.ie/.  
Simply select the Arch Linux ISO, the USB drive you want to create the bootable Arch Linux onto and click start. 

**_Note_**: _Be sure to select DD image mode from the dropdown menu or when the program asks which mode to use (ISO or DD), otherwise the image will be transferred incorrectly._

## Boot the live environment
Insert USB and start the system. Once you see some activity on the screen, press F12 a couple of times to make sure you enter the BOOT options screen. Then select the USB drive (USB HDD).

Select **Arch Linux archiso x86_64 UEFI CD** and press `e`.  
Add the following to the end of the line: `acpi_backlight=none  amdgpu.dc=0`.  
Press **Enter**.

## Pre-installation
### Set the keyboard layout
Enable `AZERTY` layout: 
```
#  loadkeys be-latin1
```  

### Connect to the Internet
Disable soft block:  
```
#  rfkill unblock all
```  
Enable network interface:  
```
#  ip link set wlp1s0 up
```  
Generate passphrase:  
```
#  wpa_passphrase "SSID" "mykey" > wpa_supplicant.conf
```  
Connect to the WIFI:  
```
#  wpa_supplicant -B -i wlp1s0 -c wpa_supplicant.conf
```  
Enable DHCP on the interface:  
```
#  dhcpcd wlp1s0
```  
Check connection:  
```
#  ping www.google.be
```  

### Update the system clock
```
#  timedatectl set-ntp true
```  

### Partition the disks
Partitioning _'GUID Partition Table (GPT)'_ using `gdisk`.  

Start gdisk:  
```
#  gdisk /dev/sda
```  
Display partition summary data with: `p`.  

Remove existing **root** partition with: `d` followed by partition number.  
_OPTIONAL: remove existing **swap** partition with command `d` followed by partition number._

Create new **root** partition with: `n` followed by:  
- Partition number  
- First Sector (previous sector + 1)  
- Last Sector **+412G**  
- Partition Type **8300** (Linux=8300)  

_OPTIONAL: create new **swap partition** with: `n` followed by:_
- _Partition number_
- _First Sector (previous sector + 1)_
- _Last Sector **+12G**_
- _Partition Type **8200** (Swap=8200)_

Save changes: `w`  
Quit: `q`

### Format the partitions
Format `root` partition with `ext4`:  
```
#  mkfs.ext4 /dev/sda<root partition>
```  

_OPTIONAL: Initialize swap partition_  
```
#  mkswap /dev/sda<swap partition>
#  swapon /dev/sda<swap partition>
```

### Mount the file systems
Mount the file system on the `root` partition to `/mnt`:   
```
#  mount /dev/sda<root partition> /mnt
```  
Create EFI mount directory:  
```
#  mkdir /mnt/efi
```  
Mount EFI:  
```
#  mount /dev/sda<efi partition> /mnt/efi
```  

## Installation
### Select the mirrors
Put server ‘Belgium’ on top in : `/etc/pacman.d/mirrorlist`.  

### Install the base packages
Use the pacstrap script to install the `base` package group:  
> _Important remark: Since the update of 2019-10-06, the kernel `linux` has te be added to pacstrap explicitely_
```
#  pacstrap /mnt base linux
```  

## Configure the system
Copy `wpa_supplicant` file to `/mnt/var` for reuse in base system:   
```
#  cp wpa_supplicant.conf /mnt/var
``` 

### Fstab
Generate an `fstab` file:  
```
#  genfstab -U /mnt >> /mnt/etc/fstab
```  

### Chroot
Change root into the new system:  
```
#  arch-chroot /mnt
```  

#### Disable beep 
```
#  echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
```  

#### Time zone
```
#  ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime  
#  hwclock --systohc
```
  
#### Localization
Uncomment `en_US.UTF-8 UTF-8` in `/etc/locale.gen` and generate with:  
```
#  locale-gen
```

Set the `LANG` variable:  
```
#  echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

Set keyboard layout:
```
#  echo "KEYMAP=be-latin1" > /etc/vconsole.conf
```

#### Network configuration
Create hostname file:  
```
#  echo "myarch" > /etc/hostname
```
Add matching entries to `hosts`:
```
#  echo -e "127.0.0.1\tlocalhost" > /etc/hosts
#  echo -e "::1\t\tlocalhost" >> /etc/hosts 	
```

#### Root password
`#  passwd`

#### User creation
```
#  useradd --create-home chris
#  passwd chris
```

#### Set mirrors
Install reflector package: 
```
#  pacman -S reflector
```  
Retrieve latest mirror list: 
```
#  reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
```

#### Install extra packages
```
#  pacman -S pacman-contrib sudo ufw wpa_supplicant vim acpi screenfetch
```  

#### Enable sudo for user
```
#  visudo  
```

Enter the following after `root ALL=(ALL) ALL`:  
```
chris ALL=(ALL) ALL
```

#### Add user to group 'wheel'
```
#  gpasswd -a chris wheel
```

#### Configure netctl
Move supplicant file:  
```
#  mv /var/wpa_supplicant.conf /etc/wpa_supplicant/
```  

Copy wpa configuration: 
```
#  cp /etc/netctl/examples/wireless-wpa /etc/netctl/
```  

Edit the copied file and change/add the following:  
```
Interface=wlp1s0  
Security=wpa-config  
WPAConfigFile='/etc/wpa_supplicant/wpa_supplicant.conf'  
```

Add `ctrl_interface=/var/run/wpa_supplicant` to `wpa_supplicant.conf` (on 1st line):  



```
ctrl_interface=/var/run/wpa_supplicant 
network={
	ssid=”MYSSID”
	#psk=”passphrase”
	psk=???
}   

```

Enable wireless connection at boot: 
```
#  netctl enable wireless-wpa
```

#### Configure GRUB bootloader
Retrieve necessary packages: 
```
#  pacman -S grub efibootmgr
```  
Install grub EFI: 
```
#  grub-install -–target=x86_64-efi –-efi-directory=/efi -–bootloader=arch
```  

Fix dark screen & hibernate:  
Edit `/etc/default/grub` and change the variable `GRUB_CMDLINE_LINUX_DEFAULT` to:  
```
"quiet acpi_backlight=none amdgpu.dc=0"
```

Generate config file: 
```
#  grub-mkconfig -o /boot/grub/grub.cfg
```

#### Install and prepare XFCE Desktop Environment
```
#  pacman -S xorg-server
#  pacman -S xfce4 xfce4-goodies
```

Install Display Manager (LightDM):  
```
#  pacman -S lightdm lightdm-gtk-greeter
```

Change Lightdm session to use `lightdm-gtk-greeter` under section **Seat** in file `/etc/lightdm/lightdm.conf`:
```
[Seat:*]
...
greeter-session=lightdm-gtk-greeter
...
```

Enable `lightdm` service:  
```
#  systemctl enable lightdm.service
```

Set keyboard layout at login in file `/etc/X11/xorg.conf.d/20-keyboard.conf`:  
```
Section "InputClass"
	Identifier "mykeyboard"
	MatchIsKeyboard "on"
	Option "XkbLayout" "be"
	Option "XkbVariant" "nodeadkeys"
EndSection
```

Enable auto-mount for usb:  
```
#  pacman -S gvfs
```

Install some extra packages:  
```
#  pacman -S firefox ttf-dejavu arc-gtk-theme arc-icon-theme papirus-icon-theme pulseaudio screenfetch xreader libreoffice galculator
```

## Reboot
Exit chroot with `exit`  
Manually unmount all the partitions: 
```
#  umount -R /mnt    
#  reboot
```

## Post installation (regular user)
### Cleaning pacman cache (except for the most recent 3) weekly:
```
$  sudo systemctl enable paccache.timer
```

### Configure and install screen locker  
Install `light-locker` and necessary packages:
```
$  sudo pacman -S light-locker xfce4-power-manager
$  xfconf-query -c xfce4-session -p /general/LockCommand -s "light-locker-command --lock" --create -t string
```

Enable `light-locker-command -l` in `/usr/bin/xflock4`:
```
# Lock by xscreensaver or gnome-screensaver, if a respective daemon is running
for lock_cmd in \
    "light-locker-command -l" \
    "xscreensaver-command -lock" \
    "gnome-screensaver-command --lock"
do
    $lock_cmd >/dev/null 2>&1 && exit
done
```

### Configure and install bluetooth
```
$  sudo pacman -S blueman
$  sudo systemctl enable bluetooth
```

Autostart blueman for users in `wheel` group in file `90-blueman.rules`:
```
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
```

### Dual boot Windows
```
$  sudo pacman -S ntfs-3g
$  sudo mkdir /mnt/windows
$  sudo mount /dev/sda<other os partition number> /mnt/windows
$  sudo pacman -S os-prober
$  sudo os-prober
$  sudo grub-mkconfig -o /boot/grub/grub.cfg
$  sudo umount /mnt/windows
```

### Install Deskjet F4100 printer
```
$  sudo pacman -S cups
$  sudo systemctl enable org.cups.cupsd.service
$  sudo pacman -S ghostscript
$  sudo pacman -S hplip
```

Now open url: http://localhost:631/  
Click `Adding Printers and Classes` and choose `Add Printer`.  
Enter root user and password.  
Follow the wizard and eventually choose the driver `HP Deskjet f4100 Series`.

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
Enter the following commands (considering '4' is the correct partition number of root installation):  
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
