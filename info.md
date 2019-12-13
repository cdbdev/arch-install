# xf86-video-amdgpu
**Q: Is the installation of this package necessary?**  
A: Xorg also includes a generic modesetting driver, which is used in the absence of the card specific xorg DDX (Device Dependent X) driver. 
Both that and amdgpu use roughly the same technologies for providing xorg/2D acceleration, so unless you need a specific functionality that 
xf86-video-amdgpu provides, yout might indeed be able to simply sustain on the modesetting driver alone. E.g. one option the xf86-video-amdgpu
provides is tearfree in order to help with tearing for non-composited xorg setups, which the modesetting driver doesn't.
