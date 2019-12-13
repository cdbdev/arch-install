# xf86-video-amdgpu
**Q: Is the installation of this package necessary?**  
**A:** Xorg also includes a generic modesetting driver, which is used in the absence of the card specific xorg DDX (Device Dependent X) driver. 
Both that and amdgpu use roughly the same technologies for providing **xorg/2D acceleration**, so unless you need a specific functionality that 
`xf86-video-amdgpu` provides, you might indeed be able to simply sustain on the modesetting driver alone. E.g. one option the `xf86-video-amdgpu`
provides is _tearfree_ in order to help with tearing for non-composited xorg setups, which the modesetting driver doesn't.

# linux-lts
In case of issues with the _stable_ kernel, you will be able to use the **LTS** version. The **LTS (long-term support)** version is advantageous if stability is your first priority. It doesn’t mean that the latest kernel, or the default kernel, is less stable, it just means that the LTS kernel won’t be updated as frequently.

# os-prober
For this package to work correctly, you also need to install the `which` package. Normally running 'grub-mkconfig' after installing the 'os-prober' package will detect other operating systems. If the `which` package is not installed, grub-mkconfig will not properly run the '30_os-prober' script under '/etc/grub.d/' (see line 33 of '30_os-prober' which assumes availability of 'which').

# Disable acpi backlight
Since the system already uses _amdgpu backlight_, you can disable the one from _acpi_.  
```bash
systemctl mask systemd-backlight@backlight:acpi_video0.service
```
