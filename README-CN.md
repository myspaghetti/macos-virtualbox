## macOS-VirtualBox 快速安装指南

使用 Bash 脚本从苹果服务器下载原版 macOS 镜像并在 VirtualBox 创建 macOS 虚拟机。

脚本需要一定的用户操作。默认情况下只需要点击几次 Enter 键即可。脚本不会安装任何闭源软件和引导程序。


### 支持 macOS Catalina (10.15)、Mojave (10.14)和 High Sierra (10.13) 

macOS Catalina 10.15.2 和 10.15.3 需要安装 VirtualBox 6.1.4。

## 说明文档

查看说明文档只需执行如下命令：`./macos-guest-virtualbox.sh documentation`

## iCloud 和 iMessage  and NVRAM

iCloud, iMessage, and other connected Apple services require a valid device name and serial number, board ID and serial number, and other genuine (or genuine-like) Apple parameters. These can be set in NVRAM by editing the script. See `documentation` for further information.

## 存储空间

The script by default assigns a target virtual disk storage size of 80GB, which is populated to about 20GB on the host on initial installation. After the installation is complete, the storage size may be increased. See `documentation` for further information.

## 图形控制器

Selecting VBoxSVGA instead of VBoxVGA for the graphics controller may considerably increase graphics performance. VBoxVGA is assigned by default for compatibility reasons.

## 暂不支持的特性

Developing and maintaining VirtualBox or macOS features is beyond the scope of this script. Some features may behave unexpectedly, such as USB device support, audio support, FileVault boot password prompt support, and other features.

### 性能

After successfully creating a working macOS virtual machine, consider importing it into QEMU/KVM so it can run with hardware passthrough at near-native performance. QEMU/KVM requires additional configuration that is beyond the scope of  the script.

### Audio

macOS may not support any built-in VirtualBox audio controllers. The bootloader [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases) may be able to load open-source audio drivers in VirtualBox.

### FileVault

The VirtualBox EFI implementation does not properly load the FileVault full disk encryption password prompt upon boot. The bootloader [OpenCore](https://github.com/acidanthera/OpenCorePkg/releases) may be able to load the password prompt.

## 依赖

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)≥6.0 with Extension Pack
* `Bash`≥4.3 (GNU variant; run on Windows through [Cygwin](https://cygwin.com/install.html) or WSL)
* `coreutils` (GNU variant; install through package manager)
* `gzip`, `unzip`, `wget`, `xxd` (install through package manager)
* `dmg2img` (install through package manager on Linux, macOS, or WSL; let the script download it automatically on Cygwin)
