## One-Key-Installation of macOS Mojave 10.14.1 on VirtualBox

The "one key" is enter, which has to be pressed whenever the virtual machine is ready for the next command. (Contrary to the script's name, the user has to use more than one key! There is one instance when the "host key" is used to release the mouse from the virtual machine, and one instance where the user has to choose [y]es or [n]o!)

The goal of the script is to allow for a very easy installation without any closed-source additions or extra bootloaders.

Tested on Cygwin, should work on Linux distros.

## iCloud and iMessage connectivity

iCloud and iMessage and other connected Apple services require a valid device serial number. Set it before the installation by replacing the empty string in `serialnumber=""` with a valid serial number, or after the installation with `VBoxManage setextradata "${vmname}" "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial" "${serialnumber}"`. An invalid serial number that matches the correct structure for the device name and board ID might work, too.

## Dependencies

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥5.2
* `Bash`≥4 (run on Windows through [Cygwin](https://cygwin.com/install.html))
* `unzip`, `wget` (install through package manager)
* `dmg2img` (install through package manager on Linux; let the script download it automaticall on Windows)
