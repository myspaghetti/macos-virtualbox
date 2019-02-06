#!/bin/bash
# One-key semi-automatic installer of macOS on VirtualBox
# (c) img2tab, licensed under GPL2.0 or higher
# url: https://github.com/img2tab/macos-guest-virtualbox
# version 0.36

# Requirements: 33.5GB available storage on host
# Dependencies: bash>=4.0, unzip, wget, dmg2img,
#               VirtualBox with Extension Pack >=5.2

# Customize the installation by setting these variables:
vmname="Mojave"             # name of the VirtualBox virtual machine
storagesize=22000           # VM disk image size in MB. minimum 22000
cpucount=2                  # VM CPU cores, minimum 2
memorysize=4096             # VM RAM in MB, minimum 2048 
gpuvram=128                 # VM video RAM in MB, minimum 34, maximum 128
resolution="1280x800"       # VM display resolution
serialnumber="NOTAVALIDSN0" # valid serial required for iCloud, iMessage.
# Structure:  PPPYWWUUUMMM - Plant, Year, Week, Unique identifier, Model
# Whether the serial is valid depends on the device name and board, below:
devicename="MacBookPro11,3" # personalize to match serial if desired
boardid="Mac-2BD1B31983FE1663"

# welcome message
whiteonred="\e[48;2;255;0;0m\e[38;2;255;255;255m"
whiteonblack="\e[48;2;0;0;9m\e[38;2;255;255;255m"
defaultcolor="\033[0m"

printf '
  One-key semi-automatic installation of macOS On VirtualBox - Mojave 10.14.3
-------------------------------------------------------------------------------

This installer uses only open-source software and original,
unmodified Apple binaries.

The script checks for dependencies and will prompt to install them if unmet.

For iCloud and iMessage connectivity, you will need to provide a valid
Apple serial number. macOS will work without it, but not Apple-connected apps.

The installation requires '${whiteonred}'33.5GB'${defaultcolor}' of available storage,
22GB for the virtual machine and 11.5GB for temporary installation files.

'${whiteonblack}'Press enter to review the script settings.'${defaultcolor}
read

# custom settings prompt
printf '
vmname="'${vmname}'"             # name of the VirtualBox virtual machine
storagesize='${storagesize}'           # VM disk image size in MB. minimum 22000
cpucount='${cpucount}'                  # VM CPU cores, minimum 2
memorysize='${memorysize}'             # VM RAM in MB, minimum 2048 
gpuvram='${gpuvram}'                 # VM video RAM in MB, minimum 34, maximum 128
resolution="'${resolution}'"       # VM display resolution
serialnumber="'${serialnumber}'" # valid serial required for iCloud, iMessage.
# Structure:  PPPYWWUUUMMM - Plant, Year, Week, Unique identifier, Model
# Whether the serial is valid depends on the device name and board, below:
devicename="'${devicename}'" # personalize to match serial if desired
boardid="'${boardid}'"

These values may be customized by editing them at the top of the script file.

'${whiteonblack}'Press enter to continue, CTRL-C to exit.'${defaultcolor}
read

# check dependencies

if [ -z "${BASH_VERSION}" ]; then
    echo "Can't determine BASH_VERSION. Exiting."
    exit
elif [ "${BASH_VERSION:0:1}" -lt 4 ]; then
    echo "Please run this script on BASH 4.0 or higher."
    exit
fi

if [ -z "$(unzip -hh 2>/dev/null)" \
     -o -z "$(wget --version 2>/dev/null)" ]; then
    echo "Please install the packages 'unzip' and 'wget'."
    exit
fi

# add ${PATH} for VirtualBox and currend directory in Cygwin

windows=""
if [ -n "$(cygcheck -V 2>/dev/null)" ]; then
    PATH="${PATH}:/cygdrive/c/Program Files/Oracle/VirtualBox:$(pwd)"
    windows="True"
fi

# VirtualBox in ${PATH}

if [ -z "$(VBoxManage -v 2>/dev/null)" ]; then
    echo "Please make sure VirtualBox is installed, and that the path to"
    echo "the VBoxManage executable is in the PATH variable."
    if [ -n "${windows}" ]; then echo -n "VBoxManage is usually installed in"
        echo "/cygdrive/c/Program Files/Oracle/VirtualBox"
        echo "and can be added with PATH=\"\${PATH}:/cygdrive/c/<...>\""
    fi
    exit
fi

# dmg2img
if [ -z "$(dmg2img -d 2>/dev/null)" ]; then
    if [ -z "${windows}" ]; then
        echo "Please install the package dmg2img."
        exit
    else
        echo "Locally installing dmg2img"
        wget -c "http://vu1tur.eu.org/tools/dmg2img-1.6.6-win32.zip" \
             -O "dmg2img-1.6.6-win32.zip" --quiet
        if [ ! -s dmg2img-1.6.6-win32.zip ]; then
             echo "Error downloading dmg2img. Please provide the package manually."
             exit
        fi
        unzip -oj "dmg2img-1.6.6-win32.zip" "dmg2img.exe"
        rm "dmg2img-1.6.6-win32.zip"
        chmod +x "dmg2img.exe"
    fi
fi

# Done with dependencies

# Initialize the VirtualBox macOS Mojave 10.14.3 virtual machine config:
echo "Initializing ${vmname} virtual machine configuration file."
if [ -n "$(VBoxManage showvminfo "${vmname}")" ]; then
    printf "${vmname}"' virtual machine already exists.
'${whiteonred}'Delete existing virtual machine "'${vmname}'"?'${defaultcolor}
    delete=""
    read -n 1 -p " [y/n] " delete 2>/dev/tty
    echo ""
    if [ "${delete}" == "y" ]; then
        VBoxManage unregistervm "${vmname}" --delete
    else
        printf '
'${whiteonblack}'Please edit the script to assign a different VM name with script variable "vmname".'${defaultcolor}
        exit
    fi
fi

# Attempt to create new virtual machine named "${vmname}"
if [ -n "$(VBoxManage createvm --name "${vmname}" --ostype "MacOS1013_64" --register 2>&1 1>/dev/null)" ]; then
    printf '
Error: Could not create virtual machine "'${vmname}'".
'${whiteonblack}'Please delete exising "'${vmname}'" VirtualBox configuration files '${whiteonred}'manually'${defaultcolor}'.

Error message:
'
    VBoxManage createvm --name "${vmname}" --ostype "MacOS1013_64" --register 2>/dev/tty
    exit
fi

# Create the macOS base system virtual disk image:
if [ -r "BaseSystem.vdi" ]; then
    echo "BaseSystem.vdi bootstrap virtual disk image ready."
else
    echo "Downloading BaseSystem.dmg from swcdn.apple.com"
    wget -c 'http://swcdn.apple.com/content/downloads/22/46/041-31308/r39g613fmms2li42if9r120zwn2bn7rnhn/BaseSystem.dmg' -O "BaseSystem.dmg" 2>/dev/tty
    if [ ! -s BaseSystem.dmg ]; then
        printf ${whiteonred}'Could not download BaseSystem.dmg'${defaultcolor}'. Please report this issue
on https://github.com/img2tab/macos-guest-virtualbox/issues
or update the URL yourself from the catalog found
on https://gist.github.com/nuomi1/16133b89c2b38b7eb197'
        exit
    fi
    echo "Downloaded BaseSystem.dmg. Converting to BaseSystem.img"
    dmg2img "BaseSystem.dmg" "BaseSystem.img"
    VBoxManage convertfromraw --format VDI "BaseSystem.img" "BaseSystem.vdi"
    rm "BaseSystem.dmg" "BaseSystem.img"
fi

echo "Creating ${vmname} virtual disk images."
# Create the target virtual disk image:
if [ -r "${vmname}.vdi" ]; then
    echo "${vmname}.vdi target system virtual disk image ready."
elif [ "${storagesize}" -lt 22000 ]; then
    echo "Attempting to install macOS Mojave on a disk smaller than 22000MB will fail."
    echo "Please assign a larger virtual disk image size."
    exit
else
    echo "Creating ${vmname} target system virtual disk image."
    VBoxManage createmedium --size="${storagesize}" \
                            --filename "${vmname}.vdi" \
                            --variant standard 2>/dev/tty
fi

# Create the installation media virtual disk image:
if [ -r "Install ${vmname}.vdi" ]; then
    echo "Installation media virtual disk image ready."
else
    echo "Creating ${vmname} installation media virtual disk image."
    VBoxManage createmedium --size=8000 \
                            --filename "Install ${vmname}.vdi" \
                            --variant fixed 2>/dev/tty
fi

# Attach virtual disk images of the base system, installation, and target
# to the virtual machine
VBoxManage storagectl "${vmname}" --add sata --name SATA --hostiocache on
VBoxManage storageattach "${vmname}" --storagectl SATA --port 0 \
           --type hdd --nonrotational on --medium "${vmname}.vdi"
VBoxManage storageattach "${vmname}" --storagectl SATA --port 1 \
           --type hdd --nonrotational on --medium "Install ${vmname}.vdi"
VBoxManage storageattach "${vmname}" --storagectl SATA --port 2 \
           --type hdd --nonrotational on --medium BaseSystem.vdi

# Configure the VM
VBoxManage modifyvm "${vmname}" --cpus "${cpucount}" --memory "${memorysize}" \
 --vram "${gpuvram}" --pae on --boot1 dvd --boot2 disk --boot3 none \
 --boot4 none --firmware efi --rtcuseutc on --usbxhci on --chipset ich9 \
 --mouse usb --keyboard usb --audio none
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "${devicename}"
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "${boardid}"
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/smc/0/Config/DeviceKey" \
 "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1
VBoxManage setextradata "${vmname}" \
 "VBoxInternal2/EfiGraphicsResolution" "${resolution}"
VBoxManage setextradata "${vmname}" \
 "VBoxInternal/Devices/efi/0/Config/DmiSystemSerial" "${serialnumber}"

# sterr back
exec 2>/dev/tty

# Start the virtual machine. This should take a couple of minutes.
VBoxManage startvm "${vmname}"

# QWERTY-to-scancode dictionary. Hex scancodes, keydown and keyup event.
# Virtualbox Mac scancodes found here:
# https://wiki.osdev.org/PS/2_Keyboard#Scan_Code_Set_1
# First half of hex code - press, second half - release, unless otherwise specified
declare -A ksc=(
    ["ESC"]="01 81"
    ["1"]="02 82" 
    ["2"]="03 83" 
    ["3"]="04 84" 
    ["4"]="05 85" 
    ["5"]="06 86" 
    ["6"]="07 87" 
    ["7"]="08 88" 
    ["8"]="09 89" 
    ["9"]="0A 8A" 
    ["0"]="0B 8B" 
    ["-"]="0C 8C" 
    ["="]="0D 8D" 
    ["BKSP"]="0E 8E"
    ["TAB"]="0F 8F"
    ["q"]="10 90" 
    ["w"]="11 91" 
    ["e"]="12 92" 
    ["r"]="13 93" 
    ["t"]="14 94" 
    ["y"]="15 95" 
    ["u"]="16 96" 
    ["i"]="17 97" 
    ["o"]="18 98" 
    ["p"]="19 99" 
    ["["]="1A 9A" 
    ["]"]="1B 9B" 
    ["ENTER"]="1C 9C"
    ["CTRLprs"]="1D"
    ["CTRLrls"]="9D"
    ["a"]="1E 9E" 
    ["s"]="1F 9F" 
    ["d"]="20 A0" 
    ["f"]="21 A1" 
    ["g"]="22 A2" 
    ["h"]="23 A3" 
    ["j"]="24 A4" 
    ["k"]="25 A5" 
    ["l"]="26 A6" 
    [";"]="27 A7" 
    ["'"]="28 A8" 
    ['`']="29 A9" 
    ["LSHIFTprs"]="2A"
    ["LSHIFTrls"]="AA"
    ['\']="2B AB" 
    ["z"]="2C AC" 
    ["x"]="2D AD" 
    ["c"]="2E AE" 
    ["v"]="2F AF" 
    ["b"]="30 B0" 
    ["n"]="31 B1" 
    ["m"]="32 B2" 
    [","]="33 B3" 
    ["."]="34 B4" 
    ["/"]="35 B5" 
    ["RSHIFTprs"]="36"
    ["RSHIFTrls"]="B6"
    ["ALTprs"]="38"
    ["ALTrls"]="B8"
    ["LALT"]="38 B8"
    ["SPACE"]="39 B9"
    [" "]="39 B9"
    ["CAPS"]="3A BA"
    ["CAPSLOCK"]="3A BA"
    ["F1"]="3B BB"
    ["F2"]="3C BC"
    ["F3"]="3D BD"
    ["F4"]="3E BE"
    ["F5"]="3F BF"
    ["F6"]="40 C0"
    ["F7"]="41 C1"
    ["F8"]="42 C2"
    ["F9"]="43 C3"
    ["F10"]="44 C4"
    ["UP"]="E0 48 E0 C8"
    ["RIGHT"]="E0 4D E0 CD"
    ["LEFT"]="E0 4B E0 CB"
    ["DOWN"]="E0 50 E0 D0"
    ["HOME"]="E0 47 E0 C7"
    ["END"]="E0 4F E0 CF"
    ["PGUP"]="E0 49 E0 C9"
    ["PGDN"]="E0 51 E0 D1"
    ["CMDprs"]="E0 5C"
    ["CMDrls"]="E0 DC"
    # all codes below start with LSHIFTprs as commented in first item:
    ["!"]="2A 02 82 AA" # LSHIFTprs 1prs 1rls LSHIFTrls
    ["@"]="2A 03 83 AA"
    ["#"]="2A 04 84 AA"
    ["$"]="2A 05 85 AA"
    ["%"]="2A 06 86 AA"
    ["^"]="2A 07 87 AA"
    ["&"]="2A 08 88 AA"
    ["*"]="2A 09 89 AA"
    ["("]="2A 0A 8A AA"
    [")"]="2A 0B 8B AA"
    ["_"]="2A 0C 8C AA"
    ["+"]="2A 0D 8D AA"
    ["Q"]="2A 10 90 AA"
    ["W"]="2A 11 91 AA"
    ["E"]="2A 12 92 AA"
    ["R"]="2A 13 93 AA"
    ["T"]="2A 14 94 AA"
    ["Y"]="2A 15 95 AA"
    ["U"]="2A 16 96 AA"
    ["I"]="2A 17 97 AA"
    ["O"]="2A 18 98 AA"
    ["P"]="2A 19 99 AA"
    ["{"]="2A 1A 9A AA"
    ["}"]="2A 1B 9B AA"
    ["A"]="2A 1E 9E AA"
    ["S"]="2A 1F 9F AA"
    ["D"]="2A 20 A0 AA"
    ["F"]="2A 21 A1 AA"
    ["G"]="2A 22 A2 AA"
    ["H"]="2A 23 A3 AA"
    ["J"]="2A 24 A4 AA"
    ["K"]="2A 25 A5 AA"
    ["L"]="2A 26 A6 AA"
    [":"]="2A 27 A7 AA"
    ['"']="2A 28 A8 AA"
    ["~"]="2A 29 A9 AA"
    ["|"]="2A 2B AB AA"
    ["Z"]="2A 2C AC AA"
    ["X"]="2A 2D AD AA"
    ["C"]="2A 2E AE AA"
    ["V"]="2A 2F AF AA"
    ["B"]="2A 30 B0 AA"
    ["N"]="2A 31 B1 AA"
    ["M"]="2A 32 B2 AA"
    ["<"]="2A 33 B3 AA"
    [">"]="2A 34 B4 AA"
    ["?"]="2A 35 B5 AA"
)

# hacky way to clear input buffer before sending scancodes
function clearinputbuffer() {
    while read -d '' -r -t 0; do read -d '' -t 0.1 -n 10000; break; done
}

# read variable kbstring and convert string to scancodes and send to guest vm
function sendkeys() {
    scancode=$(for (( i=0; i < ${#kbstring}; i++ ));
               do c[i]=${kbstring:i:1}; echo -n ${ksc[${c[i]}]}" "; done)
    scancode="${scancode} ${ksc['ENTER']}"
    clearinputbuffer
    VBoxManage controlvm "${vmname}" keyboardputscancode ${scancode}
}

# read variable kbspecial and send keystrokes by name,
# for example "CTRLprs c CTRLrls", and send to guest vm
function sendspecial() {
    scancode=""
    for keypress in ${kbspecial}; do
        scancode="${scancode}${ksc[${keypress}]}"" "
    done
    clearinputbuffer
    VBoxManage controlvm "${vmname}" keyboardputscancode ${scancode}
}

function sendenter() {
    kbspecial="ENTER"
    sendspecial
}
 
function promptlangutils() {
printf ${whiteonblack}'
Press enter when the Language window is ready.'${defaultcolor}
read -p ""
sendenter

printf ${whiteonblack}'
Press enter when the macOS Utilities window is ready.'${defaultcolor}
read -p ""

kbspecial='CTRLprs F2 CTRLrls u ENTER t ENTER'
sendspecial
}

function promptterminalready() {
printf ${whiteonblack}'
Press enter when the Terminal command prompt is ready.'${defaultcolor}
read -p ""
}

promptlangutils
promptterminalready

echo ""
echo "Partitioning target virtual disk."

# get "physical" disks from largest to smallest
kbstring='disks="$(diskutil list | grep -o "[0-9][^ ]* GB *disk[012]$" | sort -gr | grep -o disk[012])"; disks=(${disks[@]})'
sendkeys

# partition largest disk as APFS
kbstring='diskutil partitionDisk "/dev/${disks[0]}" 1 GPT APFS "'"${vmname}"'" R'
sendkeys
promptterminalready
echo ""
echo "Partitioning installer virtual disk."

# partition second-largest disk as JHFS+
kbstring='diskutil partitionDisk "/dev/${disks[1]}" 1 GPT JHFS+ "Install" R'
sendkeys
promptterminalready
echo ""
echo "Downloading macOS Mojave 10.14.3 installer."

# downloading macOS
kbstring='urlpath="http://swcdn.apple.com/content/downloads/22/46/041-31308/r39g613fmms2li42if9r120zwn2bn7rnhn/"; for filename in BaseSystem.chunklist InstallInfo.plist AppleDiagnostics.dmg AppleDiagnostics.chunklist BaseSystem.dmg InstallESDDmg.pkg; do curl "${urlpath}${filename}" -o "/Volumes/'"${vmname}"'/${filename}"; done'
sendkeys
promptterminalready
echo ""
echo "Loading base system onto installer virtual disk"

# Create secondary base system and shut down the virtual machine
kbstring='asr restore --source /Volumes/'"${vmname}"'/BaseSystem.dmg --target /Volumes/Install --erase --noprompt'
sendkeys

promptterminalready

kbstring='shutdown -h now'
sendkeys

printf ${whiteonblack}'
Shutting down virtual machine.
Press enter when the virtual machine shutdown is complete.'${defaultcolor}
read -p ""

# Detach the original 2GB BaseSystem.vdi and boot from the new 8GB BaseSystem
echo ""
echo "Detaching initial base system and starting virtual machine."
echo "The VM will boot from the new base system on the installer virtual disk."
VBoxManage storageattach "${vmname}" --storagectl SATA --port 2 --medium none
VBoxManage startvm "${vmname}"

promptlangutils
promptterminalready
echo ""
echo "Moving installation files to installer virtual disk."
echo "The virtual machine may report that disk space is critically low; this is fine."
kbstring='mount -rw / && installpath="/Install macOS Mojave.app/Contents/SharedSupport/" && mkdir -p "${installpath}" && cd "/Volumes/'"${vmname}/"'" && mv *.chunklist *.plist *.dmg *.pkg "${installpath}"'
sendkeys

# Rename InstallESDDmg.pkg to InstallESD.dmg and update InstallInfo.plist
promptterminalready
kbstring='mv "${installpath}InstallESDDmg.pkg" "${installpath}InstallESD.dmg" && sed -i.bak -e "s/InstallESDDmg\.pkg/InstallESD.dmg/" -e "s/pkg\.InstallESDDmg/dmg.InstallESD/" "${installpath}InstallInfo.plist" && sed -i.bak2 -e "/InstallESD\.dmg/{n;N;N;N;d;}" "${installpath}InstallInfo.plist"'
sendkeys

# reboot, because the installer does not work when the partition is remounted
promptterminalready
kbstring="reboot"
sendkeys
echo ""
echo "Rebooting the virtual machine"
promptlangutils
promptterminalready

# Start the installer.
kbstring='cd "/Install macOS Mojave.app/Contents/Resources/"; ./startosinstall --volume "/Volumes/'"${vmname}"'"'
sendkeys
printf ${whiteonblack}'
Installer started. Please wait for the license prompt to appear at
the bottom of the virtual machine terminal, then press enter here.
This will accept the license on the virtual machine.'${defaultcolor}
read -p ""
kbspecial="A ENTER"
sendspecial

echo ""
echo "When the installer finishes preparing, the virtual machine will reboot"
echo "into the base system, not the installer."
printf ${whiteonblack}'
After the reboot, press enter when the Language window or Utilities window is ready.'${defaultcolor}
read -p ""
sendenter

printf ${whiteonblack}'
Press enter when the macOS Utilities window is ready.'${defaultcolor}
read -p ""

# Start Safari (Get Help Online)
kbspecial="UP UP UP UP DOWN DOWN TAB SPACE"
sendspecial

printf ${whiteonblack}'
Press enter when Safari is ready.'${defaultcolor}
read -p ""

# Browse the web!
kbspecial="CMDprs l CMDrls"
sendspecial
kbstring="https://github.com/acidanthera/AppleSupportPkg/releases/tag/2.0.4"
sendkeys
echo ""
printf 'In the VM, '${whiteonred}'manually'${defaultcolor}' right-click on AppleSupport-v2.0.4-RELEASE.zip'
echo ""
echo "and click 'Download Linked File As...' then from the dropdown menu"
echo "select '${vmname}' for 'Where:', then unbind the mouse cursor from the virtual"
printf 'machine with the '${whiteonblack}'right control key.'${defaultcolor}
echo ""
read -p "Click here and press enter when the download is complete."

kbspecial="CMDprs q CMDrls"
sendspecial
printf ${whiteonblack}'
Press enter when the macOS Utilities window is ready.'${defaultcolor}
read -p ""
kbspecial="CTRLprs F2 CTRLrls u ENTER t ENTER"
sendspecial
promptterminalready

# find largest drive
kbstring='disks="$(diskutil list | grep -o "[0-9][^ ]* GB *disk[012]$" | sort -gr | grep -o disk[012])"; disks=(${disks[@]})'
sendkeys

# move drivers into path on EFI partition
kbstring='mkdir -p "/Volumes/'"${vmname}"'/mount_efi" && mount_msdos /dev/${disks[0]}s1 "/Volumes/'"${vmname}"'/mount_efi" && mkdir -p "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/" && cd "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/" && tar -xf "/Volumes/'"${vmname}"'/AppleSupport-v2.0.4-RELEASE.zip" && cd "Drivers/" && mv *.efi "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/"'
sendkeys

# create startup.nsh EFI script
kbstring='cd "/Volumes/'"${vmname}"'/mount_efi/" && vim startup.nsh'
sendkeys

printf ${whiteonblack}'
Press enter when '${defaultcolor}'"startup.nsh" [New File]'${whiteonblack}' appears
at the bottom of the terminal.'${defaultcolor}
read -p ""

kbstring='Iecho -off'; sendkeys
kbstring='load fs0:\EFI\driver\AppleImageLoader.efi'; sendkeys
kbstring='load fs0:\EFI\driver\AppleUiSupport.efi'; sendkeys
kbstring='load fs0:\EFI\driver\ApfsDriverLoader.efi'; sendkeys
kbstring='map -r'; sendkeys
kbstring='for %a run (1 5)'; sendkeys
kbstring='  fs%a:'; sendkeys
kbstring='  cd "macOS Install Data\Locked Files\Boot Files"'; sendkeys
kbstring='  boot.efi'; sendkeys
kbstring='  cd "System\Library\CoreServices"'; sendkeys
kbstring='  boot.efi'; sendkeys
kbstring='endfor'; sendkeys
kbspecial="ESC : w q ENTER"; sendspecial

# Shut down the virtual machine
printf ${whiteonblack}'
Press enter when the terminal is ready.'${defaultcolor}
read -p ""
kbstring='shutdown -h now'
sendkeys

echo ""
echo "Shutting down virtual machine."
printf ${whiteonblack}'
Press enter when the virtual machine shutdown is complete.'${defaultcolor}
read -p ""

# detach installer from virtual machine
VBoxManage storageattach "${vmname}" --storagectl SATA --port 1 --medium none

# Start the virtual machine again.
# The VM will boot from the target virtual disk image and complete the installation.
VBoxManage startvm "${vmname}"

printf '
macOS Mojave 10.14.3 will now install and start up.

'${whiteonred}'Delete temporary files?'${defaultcolor}
delete=""
read -n 1 -p " [y/n] " delete 2>/dev/tty
echo ""
if [ "${delete}" == "y" ]; then
# temporary files cleanup
    VBoxManage closemedium "BaseSystem.vdi"
    VBoxManage closemedium "Install ${vmname}.vdi"
    rm "BaseSystem.vdi" "Install ${vmname}.vdi"
fi

printf 'macOS Mojave 10.14.3 installation should complete in a few minutes.

After the installation is complete, you may wish to expand the virtual disk
image size through VirtualBox, and then expand the macOS system partition
through Disk Utility in the virtual machine itself.

That'\''s it. Enjoy your virtual machine.'
