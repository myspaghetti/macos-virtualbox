## Semi-automatic installer of macOS on VirtualBox

### Supports macOS Mojave (10.14) and High Sierra (10.13)
### macOS Catalina 10.15.2 fails to boot on VirtualBox as of the date of its release. Earlier versions of Catalina work, but they are not currently being distributed by Apple's software update servers, from which the script fetches the installer.

The script is semi-automatic and requires a little user interaction. A default fresh install only requires the user to sit patiently and, ten times, press enter when prompted.

The goal of the script is to allow for a very easy installation without any closed-source additions or extra bootloaders.

Tested on Cygwin. Works on macOS and WSL, should work on most Linux distros.

## iCloud and iMessage connectivity
iCloud, iMessage, and other connected Apple services require a valid device name and serial number, board ID and serial number, and other genuine (or genuine-like) Apple parameters. These parameters may be set in the script before installation, and applied by booting into the EFI Internal Shell, by powering up the VM and immediately pressing Esc when the VirtualBox logo appears. This boots into the boot menu or EFI Internal Shell. From the boot menu, select "Boot Manager" and then "EFI Internal Shell" and allow `startup.nsh` script to run, applying the EFI and NVRAM variables. Otherwise, set the EFI and NVRAM variables after installation by running `./macos-guest-virtualbox.sh configure_vm create_macos_installation_files_viso` and copying the generated `startup.nsh` file to the root of the boot EFI partition. From the VirtualBox manager, attach the VISO to the virtual machine and boot macOS, start Terminal, and execute the following, making sure to replace `/Volumes/path/to/VISO/startup.nsh` with the correct path: `mkdir EFI` `sudo su # this will prompt for a password` `mount_ntfs /dev/disk0s1 EFI` `cp /Volumes/path/to/VISO/startup.nsh ./EFI/startup.nsh` . After copying `startup.nsh`, boot into the EFI Internal Shell as desribed in the beginning of this section.

## Storage size

The script by default assigns a target virtual disk storage size of 80GB, which is populated to about 15GB on the host on initial installation. After the installation is complete, the storage size may be increased. First increase the virtual disk image size through VirtualBox Manager or `VBoxManage`, then in Terminal in the virtual machine run `sudo diskutil repairDisk disk0`, and then `sudo diskutil apfs resizeContainer disk1 0` or from Disk Utility, after repairing the disk from Terminal, delete the "Free space" partition so it allows the system APFS container to take up the available space.

## Performance and unsupported features

Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. Some features may behave unexpectedly, such as USB device support, audio support, and other features.

After successfully creating a working macOS virtual machine, consider importing it into QEMU/KVM so it can run with hardware passthrough at near-native performance. QEMU/KVM requires additional configuration that is beyond the scope of  the script.

## Dependencies

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥6.0 with Extension Pack
* `Bash`≥4.3 (GNU variant; run on Windows through [Cygwin](https://cygwin.com/install.html) or WSL)
* `coreutils` (GNU variant; install through package manager)* `unzip``` (install through package manager)
* `unzip` (install through package manager)
* `wget` (install through package manager)
* `dmg2img` (install through package manager on Linux, macOS, or WSL; let the script download it automatically on Cygwin)
