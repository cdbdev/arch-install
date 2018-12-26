# Installation guide
This guide documents the specific steps needed to install Arch Linux on my Lenovo ideapad 320.

## Installation media
Download an installation image from https://www.archlinux.org/download/ and create the installation media:

In **GNU/Linux**:
Run the following command, replacing /dev/sdx with your drive, e.g. /dev/sdb. (Do not append a partition number, so do not use something like /dev/sdb1):

dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx status=progress oflag=sync

In **Windows**:

Using Rufus from https://rufus.akeo.ie/. 

Simply select the Arch Linux ISO, the USB drive you want to create the bootable Arch Linux onto and click start. 
Note: Be sure to select DD image mode from the dropdown menu or when the program asks which mode to use (ISO or DD), otherwise the image will be transferred incorrectly.
