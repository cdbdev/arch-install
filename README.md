# Installation guide
This guide documents the specific steps needed to install Arch Linux on my Lenovo ideapad 320.

## Installation media
Download an installation image from https://www.archlinux.org/download/ and create the installation media:

In **GNU/Linux**:
Run the following command, replacing /dev/sdx with your drive, e.g. /dev/sdb. (Do not append a partition number, so do not use something like /dev/sdb1):

`dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx status=progress oflag=sync`

In **Windows**:

Using Rufus from https://rufus.akeo.ie/.  
Simply select the Arch Linux ISO, the USB drive you want to create the bootable Arch Linux onto and click start. 

**_Note_**: _Be sure to select DD image mode from the dropdown menu or when the program asks which mode to use (ISO or DD), otherwise the image will be transferred incorrectly._

## Boot the live environment
Insert USB and start the system. Once you see some activity on the screen, press F12 a couple of times to make sure you enter the BOOT options screen. Then select the USB drive (USB HDD).

Select _'Arch Linux archiso x86_64 UEFI CD'_ and press `e`.  
Add the following to the end of the line: `acpi_backlight=none  amdgpu.dc=0`.  
Press ‘Enter’.

## Pre-installation
### Set the keyboard layout
Enable 'AZERTY' layout: `loadkeys be-latin1`  

### Connect to the Internet
Disable soft block: `rfkill unblock all`  
Enable network interface: `ip link set wlp1s0 up`  
Generate passphrase: `wpa_passphrase "SSID" "mykey" > wpa_supplicant.conf`  
Connect to the WIFI: `wpa_supplicant -B -i wlp1s0 -c wpa_supplicant.conf`  
Enable DHCP on the interface: `dhcpcd wlp1s0`  
Check connection: `ping www.google.be`  

### Update the system clock
`timedatectl set-ntp true`  

### Partition the disks
Because I have a _'GUID Partition Table (GPT)'_, I'll be using **gdisk**.  

Start gdisk: `gdisk /dev/sda`  
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
Format **root** partition with **ext4**: `mkfs.ext4 /dev/sda<root partition>`  

_OPTIONAL: Initialize swap partition_  
```
mkswap /dev/sda<swap partition>
swapon /dev/sda<swap partition>
```

### Mount the file systems
Mount the file system on the root partition to /mnt: `mount /dev/sda<root partition> /mnt`  
Create EFI mount directory: `mkdir /mnt/efi`  
Mount EFI: `mount /dev/sda<efi partition> /mnt/efi`  

## Installation
### Select the mirrors
Put server ‘Belgium’ on top in : **/etc/pacman.d/mirrorlist**.  

### Install the base packages
Use the pacstrap script to install the base package group: `pacstrap /mnt base`  

## Configure the system
Copy _'wpa_supplicant'_ file to **/mnt/var** for reuse in base system: `cp wpa_supplicant.conf /mnt/var`  

### Fstab
Generate an fstab file: `genfstab -U /mnt >> /mnt/etc/fstab`  

### Chroot
Change root into the new system: `arch-chroot /mnt`  

#### Disable beep 
`echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf`  

#### Time zone
  ```
  ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime  
  hwclock --systohc
  ```
  
#### Localization
Uncomment `en_US.UTF-8 UTF-8` in `/etc/locale.gen`  
Generate locale: `locale-gen`  

Enter in : _/etc/locale.conf_:  
`LANG=en_US.UTF-8`

Enter in : _/etc/vconsole.conf_:  
`KEYMAP=be-latin1`

#### Network configuration
Enter in: _/etc/hostname_:  
`myarch`

Enter in: _/etc/hosts_:  
```
127.0.0.1 localhost
::1       localhost
```	

#### Root password
`passwd`

#### User creation
```
useradd --create-home chris
passwd chris
```

#### Set mirrors
Install reflector package: `pacman -S reflector`  
Retrieve latest mirror list: `reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist`

#### Install extra packages
`pacman -S pacman-contrib sudo ufw wpa_supplicant vim acpi`  

#### Enable sudo for user
`visudo`  
Enter the following after _'root ALL=(ALL) ALL'_:  
`chris ALL=(ALL) ALL`

#### Add user to group 'wheel'
`gpasswd -a chris wheel`

#### Configure netctl
Move supplicant file: `mv /var/wpa_supplicant.conf /etc/wpa_supplicant/`  
Copy wpa configuration: `cp /etc/netctl/examples/wireless-wpa /etc/netctl/`  
Edit the copied file and change/add the following:  
```
Interface=wlp1s0  
Security=wpa-config  
WPAConfigFile='/etc/wpa_supplicant/wpa_supplicant.conf'  
```
Add **ctrl_interface=/var/run/wpa_supplicant** to _'wpa_supplicant.conf'_ (on 1st line):  
```
ctrl_interface=/var/run/wpa_supplicant 
network={
	ssid=”MYSSID”
	#psk=”passphrase”
	psk=???
}   

```

Enable wireless connection at boot: `netctl enable wireless-wpa`

#### Configure GRUB bootloader
Retrieve necessary packages: `pacman -S grub efibootmgr`  
Install grub EFI: `grub-install -–target=x86_64-efi –-efi-directory=/efi -–bootloader=arch`  

Fix dark screen & hibernate:  
Edit _'/etc/default/grub'_ and add the following to variable GRUB_CMDLINE_LINUX_DEFAULT after _“quiet”_:  
`acpi_backlight=none  amdgpu.dc=0`

Generate config file: `grub-mkconfig -o /boot/grub/grub.cfg`

## Reboot
Exit chroot: `exit`  
Manually unmount all the partitions: `umount -R /mnt`  
`reboot`

