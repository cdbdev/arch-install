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

_OPTIONAL: create new **swap partition** with: `n` followed by:
- Partition number
- First Sector (previous sector + 1)  
- Last Sector **+12G**  
- Partition Type **8200** (Swap=8200)_

Save changes: `w`  
Quit: `q`

### Format the partitions
