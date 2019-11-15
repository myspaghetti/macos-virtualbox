## Semi-automatic installer of macOS on VirtualBox

### Supports macOS Catalina (10.15), Mojave (10.14), and High Sierra (10.13)

The script is semi-automatic and requires a little user interaction. Most of the time the user simply has to press enter. There is one step where the user has to choose between [C]atalina, [M]ojave, or [H]igh Sierra, and a couple of instances where the user has to choose whether to delete or keep temporary files and previous installations.

The goal of the script is to allow for a very easy installation without any closed-source additions or extra bootloaders.

Tested on Cygwin. Works on macOS and WSL, should work on most Linux distros.

## iCloud and iMessage connectivity

iCloud, iMessage, and other connected Apple services require a valid device name and serial number, board ID and serial number, and other genuine (or genuine-like) Apple parameters. These parameters may be set in the script before installation, or set after installation and applied with `./macos-guest-virtualbox.sh configure_vm`

## Storage size

The script by default assigns the minimum required storage size for the installation of Catalina. After the installation is complete, the storage size may be increased. First increase the virtual disk image size through VirtualBox Manager or `VBoxManage`, then in Terminal in the virtual machine run `sudo diskutil repairDisk disk0`, and then `sudo diskutil apfs resizeContainer disk1 0` or from Disk Utility, after repairing the disk from Terminal, delete the "Free space" partition so it allows the system APFS container to take up the available space.

## Performance and unsupported features

Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. Some features may behave unexpectedly, such as USB device support, audio support, and other features.

After successfully creating a working macOS virtual machine, consider importing it into QEMU/KVM so it can run with hardware passthrough at near-native performance. QEMU/KVM requires additional configuration that is beyond the scope of  the script.

## Dependencies

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥6.0 with Extension Pack
* `Bash`≥4 (GNU variant; run on Windows through [Cygwin](https://cygwin.com/install.html) or WSL)
* `coreutils` (GNU variant; install through package manager)
* `unzip` (install through package manager)
* `wget` (install through package manager)
* `dmg2img` (install through package manager on Linux, macOS, or WSL; let the script download it automatically on Cygwin)
