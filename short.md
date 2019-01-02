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
```
