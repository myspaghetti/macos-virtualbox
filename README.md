![macOS virtual machine showing apps on Launchpad](https://repository-images.githubusercontent.com/156108442/c04dcf80-8eae-11ea-9620-020f8a863fec "macos-guest-virtualbox.sh")
## Push-button installer of macOS on VirtualBox
[`macos-guest-virtualbox.sh`](https://raw.githubusercontent.com/myspaghetti/macos-guest-virtualbox/master/macos-guest-virtualbox.sh) is a Bash script that creates a macOS virtual machine guest on VirtualBox with unmodified macOS installation files downloaded directly from Apple servers. Tested on [Cygwin](https://cygwin.com/install.html). Works on macOS, Windows Subsystem for Linux, and centOS 7. Should work on most modern Linux distros.

A default install only requires the user to sit patiently and, less than ten times, press enter when prompted by the script, without interacting with the virtual machine.

### macOS Catalina (10.15), Mojave (10.14), and High Sierra (10.13) currently supported.

## Documentation
Documentation can be viewed by executing the command `./macos-guest-virtualbox.sh documentation`

The majority of the script is either documentation, comments, or actionable error messages, which should make the script straightforward to inspect and understand.

## iCloud and iMessage connectivity and NVRAM
iCloud, iMessage, and other connected Apple services require a valid device name and serial number, board ID and serial number, and other genuine (or genuine-like) Apple parameters. These can be set in NVRAM by editing the script. See `documentation` for further information.

## Storage size
The script by default assigns a target virtual disk storage size of 80GB, which is populated to about 25GB on the host on initial installation. After the installation is complete, the storage size may be increased. See `documentation` for further information.

## Primary display resolution
The following primary display resolutions are supported by macOS on VirtualBox: `5120x2880` `2880x1800` `2560x1600` `2560x1440` `1920x1200` `1600x1200` `1680x1050` `1440x900` `1280x800` `1024x768` `640x480`. See `documentation` for further information.

## Unsupported features
Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. Some features may behave unexpectedly, such as USB device support, audio support, FileVault boot password prompt support, and other features.

#### Performance and deployment
After successfully creating a working macOS virtual machine, consider importing it into more performant virtualization software, or packaging it for configuration management platforms for automated deployment. These virtualization and deployment applications require additional configuration that is beyond the scope of the script.

QEMU with KVM is capable of providing virtual machine hardware passthrough for near-native performance. QEMU supports the `VMDK` virtual disk image storage format, which can be configured to be created by the script. See `documentation` for further information. QEMU and KVM require additional configuration that is beyond the scope of the script.

#### Bootloaders
The macOS VirtualBox guest is loaded without extra bootloaders, but it is compatible with [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases). OpenCore requires additional configuration that is beyond the scope of  the script.

#### Audio
macOS may not support any built-in VirtualBox audio controllers. The bootloader [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases) may be able to load open-source or built-in audio drivers in VirtualBox, providing the configuration for STAC9221 (Intel HD Audio) or SigmaTel STAC9700,83,84 (ICH AC97) is available.

#### Display scaling
VirtualBox does not supply an EDID for its virtual display, and macOS does not enable display scaling (high PPI) without an EDID. The bootloader OpenCore can [inject an EDID](https://github.com/acidanthera/WhateverGreen/blob/master/Manual/FAQ.IntelHD.en.md#edid) which enables display scaling.

#### FileVault
The VirtualBox EFI implementation does not properly load the FileVault full disk encryption password prompt upon boot. The bootloader [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases/tag/0.5.8) is able to load the password prompt with the parameter `ProvideConsoleGop` set to `true`. See sample [config.plist](https://github.com/myspaghetti/macos-virtualbox/files/4640669/config.plist.txt). 

## Dependencies
All the dependencies should be available through a package manager:  
`bash` `coreutils` `gzip` `unzip` `wget` `xxd` `dmg2img`  `virtualbox`

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥6.1.6 with Extension Pack, though versions as low as 5.2 may work.
* GNU `Bash`≥4.3, on Windows run through [Cygwin](https://cygwin.com/install.html) or WSL.
* GNU `coreutils`≥8.22, GNU `gzip`≥1.5, Info-ZIP `unzip`≥v6.0, GNU `wget`≥1.14, `xxd`≥1.7
* `dmg2img`≥1.6.5, on Cygwin the package is not available through the package manager so the script downloads it automatically.
