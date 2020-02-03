## Semi-automatic installer of macOS on VirtualBox
This is a Bash script that creates a VirtualBox guest macOS virtual machine with unmodified macOS installation files downloaded directly from Apple servers.

The script is semi-automatic and requires a little user interaction. A default install only requires the user to sit patiently and, less than ten times, press enter when prompted. The script doesn't install any closed-source additions or extra bootloaders. Tested on Cygwin. Works on macOS and WSL, should work on most Linux distros.

### macOS Mojave (10.14) and High Sierra (10.13) currently supported
#### macOS Catalina 10.15.2 and 10.15.3 fail to boot on VirtualBox. Earlier versions of Catalina work, but they are not currently being distributed by Apple's software update servers, from which the script fetches the installer. A workaround for Catalina 10.15.2 and 10.15.3 is [available](https://github.com/myspaghetti/macos-guest-virtualbox/issues/134#issuecomment-578764413) involving using earlier versions of `boot.efi`.

## Documentation
Documentation can be viewed by executing the command `./macos-guest-virtualbox.sh documentation`

## iCloud and iMessage connectivity and NVRAM
iCloud, iMessage, and other connected Apple services require a valid device name and serial number, board ID and serial number, and other genuine (or genuine-like) Apple parameters. These can be set in NVRAM by editing the script. See `documentation` for further information.

## Storage size
The script by default assigns a target virtual disk storage size of 80GB, which is populated to about 15GB on the host on initial installation. After the installation is complete, the storage size may be increased. See `documentation` for further information.

## Graphics controller
Selecting VBoxSVGA instead of VBoxVGA for the graphics controller may considerably increase graphics performance. VBoxVGA is assigned by default for compatibility reasons.

## Audio
macOS may not support any built-in VirtualBox audio controllers. The open-source VoodooHDA drivers may work in VirtualBox, but they tend to hang the virtual machine.

## Performance and unsupported features
Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. Some features may behave unexpectedly, such as USB device support, audio support, and other features.

After successfully creating a working macOS virtual machine, consider importing it into QEMU/KVM so it can run with hardware passthrough at near-native performance. QEMU/KVM requires additional configuration that is beyond the scope of  the script.

## Dependencies
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥6.0 with Extension Pack
* `Bash`≥4.3 (GNU variant; run on Windows through [Cygwin](https://cygwin.com/install.html) or WSL)
* `coreutils` (GNU variant; install through package manager)
* `gzip`, `unzip`, `wget`, `xxd` (install through package manager)
* `dmg2img` (install through package manager on Linux, macOS, or WSL; let the script download it automatically on Cygwin)
