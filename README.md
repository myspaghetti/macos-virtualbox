## One-key semi-automatic installer of macOS Mojave 10.14 on VirtualBox

The "one key" is enter, which has to be pressed whenever the virtual machine is ready for the next command. (Contrary to the script's name, the user has to use more than one key! There is one instance when the "host key" is used to release the mouse from the virtual machine, and a couple of instances where the user has to choose [y]es or [n]o!)

The goal of the script is to allow for a very easy installation without any closed-source additions or extra bootloaders.

Tested on Cygwin and WSL, should work on most Linux distros.

## iCloud and iMessage connectivity

iCloud and iMessage and other connected Apple services require a valid device serial number. Set it before the installation by replacing `NOTAVALIDSN0` with a valid serial number, or after the installation with `VBoxManage setextradata "${vmname}" "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial" "${serialnumber}"`. An invalid serial number that matches the correct structure for the device name and board ID might work, too.

## Storage size

The script assigns the minimum required storage size for the installation. After the installation is complete, the virtual disk image may be increased through VirtualBox, and then the macOS system partition size may be increased. Inside the virtual machine run `sudo diskutil repairDisk disk0` and then from Disk Utility delete the "Free space" partition, allowing the system APFS container to take up the space.

## Unsupported features

Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. [Audio support](https://github.com/chris1111/VoodooHDA-2.9.0-Clover-V12/releases), USB device support, and other features are not currently implemented for macOS guests on Windows and Linux hosts.

## Dependencies

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥5.2 with Extension Pack
* `Bash`≥4 (run on Windows through [Cygwin](https://cygwin.com/install.html) or WSL) with `coreutils`
* `unzip`, `wget` (install through package manager)
* `dmg2img` (install through package manager on Linux or WSL; let the script download it automatically on Cygwin)
