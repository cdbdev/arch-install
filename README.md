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

Select _Arch Linux archiso x86_64 UEFI CD_ and press `e`.  
Add the following to the end of the line: `acpi_backlight=none  amdgpu.dc=0`.  
Press ‘Enter’.
