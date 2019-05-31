#!/bin/bash
# One-key semi-automatic installer of macOS on VirtualBox
# (c) img2tab, licensed under GPL2.0 or higher
# url: https://github.com/img2tab/macos-guest-virtualbox
# version 0.63.0

# Requirements: 37.5GB available storage on host
# Dependencies: bash>=4.0, unzip, wget, dmg2img,
#               VirtualBox with Extension Pack >=5.2

# Customize the installation by setting these variables:
vmname="macOS Mojave"       # name of the VirtualBox virtual machine
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

function welcome() {
printf '
   One-key semi-automatic installation of macOS On VirtualBox - Mojave 10.14
-------------------------------------------------------------------------------

This script installs only open-source software and unmodified Apple binaries.

The script checks for dependencies and will prompt to install them if unmet.
Some stages may fail due to errant keyboard presses; run the script with
"'${whiteonblack}"${0}"' stages'${defaultcolor}'" to see how to run only certain stages.

For iCloud and iMessage connectivity, you will need to provide a valid
Apple serial number. macOS will work without it, but not Apple-connected apps.

The installation requires '${whiteonred}'37.5GB'${defaultcolor}' of available storage,
22GB for the virtual machine and 15.5GB for temporary installation files.

'${whiteonblack}'Press enter to review the script settings.'${defaultcolor}
read

# custom settings prompt
printf '
vmname="'"${vmname}"'"       # name of the VirtualBox virtual machine
storagesize='"${storagesize}"'           # VM disk image size in MB. minimum 22000
cpucount='"${cpucount}"'                  # VM CPU cores, minimum 2
memorysize='"${memorysize}"'             # VM RAM in MB, minimum 2048 
gpuvram='"${gpuvram}"'                 # VM video RAM in MB, minimum 34, maximum 128
resolution="'"${resolution}"'"       # VM display resolution
serialnumber="'"${serialnumber}"'" # valid serial required for iCloud, iMessage.
# Structure:  PPPYWWUUUMMM - Plant, Year, Week, Unique identifier, Model
# Whether the serial is valid depends on the device name and board, below:
devicename="'"${devicename}"'" # personalize to match serial if desired
boardid="'"${boardid}"'"

These values may be customized by editing them at the top of the script file.

'${whiteonblack}'Press enter to continue, CTRL-C to exit.'${defaultcolor}
read
}

# check dependencies
function check_dependencies() {
# check if running on macOS
if [ -n "$(sw_vers 2>/dev/null)" ]; then
    printf '\nThis script is not tested on macOS. Exiting.\n'
    exit
fi

# check Bash version
if [ -z "${BASH_VERSION}" ]; then
    echo "Can't determine BASH_VERSION. Exiting."
    exit
elif [ "${BASH_VERSION:0:1}" -lt 4 ]; then
    echo "Please run this script on BASH 4.0 or higher."
    exit
fi

# check for unzip, coreutils, wget
if [ -z "$(unzip -hh 2>/dev/null)" \
     -o -z "$(head --version 2>/dev/null)" \
     -o -z "$(wget --version 2>/dev/null)" ]; then
    echo "Please make sure the following packages are installed:"
    echo "coreutils   unzip   wget"
    exit
fi

# wget supports --show-progress from version 1.16
if [[ "$(wget --version 2>/dev/null | head -n 1)" =~ 1\.1[6-9]|1\.2[0-9] ]]; then
    wgetargs="--quiet --continue --show-progress"  # pretty
else
    wgetargs="--continue"  # ugly
fi

# VirtualBox in ${PATH}
# Cygwin
if [ -n "$(cygcheck -V 2>/dev/null)" ]; then
    if [ -n "$(cmd.exe /d /s /c call VBoxManage.exe -v 2>/dev/null)" ]; then
        function VBoxManage() {
            cmd.exe /d /s /c call VBoxManage.exe "$@"
        }
    else
        cmd_path_VBoxManage='C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
        echo "Can't find VBoxManage in PATH variable,"
        echo "checking ${cmd_path_VBoxManage}"
        if [ -n "$(cmd.exe /d /s /c call "${cmd_path_VBoxManage}" -v 2>/dev/null)" ]; then
            function VBoxManage() {
                cmd.exe /d /s /c call "${cmd_path_VBoxManage}" "$@"
            }
            echo "Found VBoxManage"
        else
            echo "Please make sure VirtualBox is installed, and that the path to the"
            echo "VBoxManage.exe executable is in the PATH variable, or assigned in the script"
            printf 'to the variable '${whiteonblack}'cmd_path_VBoxManage'${defaultcolor}' including the name of the executable.'
            exit
        fi
    fi
# Windows Subsystem for Linux (WSL)
elif [[ "$(cat /proc/sys/kernel/osrelease 2>/dev/null)" =~ Microsoft ]]; then
    if [ -n "$(VBoxManage.exe -v 2>/dev/null)" ]; then
        function VBoxManage() {
            VBoxManage.exe "$@"
        }
    else
        wsl_path_VBoxManage='/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe'
        echo "Can't find VBoxManage in PATH variable,"
        echo "checking ${wsl_path_VBoxManage}"
        if [ -n "$("${wsl_path_VBoxManage}" -v 2>/dev/null)" ]; then
            function VBoxManage() {
                "${wsl_path_VBoxManage}" "$@"
            }
            echo "Found VBoxManage"
        else
            echo "Please make sure VirtualBox is installed on Windows, and that the path to the"
            echo "VBoxManage.exe executable is in the PATH variable, or assigned in the script"
            printf 'to the variable '${whiteonblack}'wsl_path_VBoxManage'${defaultcolor}' including the name of the executable.'
            exit
        fi
    fi
# everything else (not cygwin and not wsl)
elif [ -z "$(VBoxManage -v 2>/dev/null)" ]; then
    echo "Please make sure VirtualBox is installed, and that the path to the"
    echo "VBoxManage executable is in the PATH variable."
    exit
fi

# Oracle VM VirtualBox Extension Pack
extpacks="$(VBoxManage list extpacks 2>/dev/null)"
if [ "$(expr match "${extpacks}" '.*Oracle VM VirtualBox Extension Pack')" -le "0" \
    -o "$(expr match "${extpacks}" '.*Usable:[[:blank:]]*false')" -gt "0" ]; then
    echo "Please make sure Oracle VM VirtualBox Extension Pack is installed, and that"
    echo "all installed VirtualBox extensions are listed as usable in \"VBoxManage list extpacks\""
    exit
fi

# dmg2img
if [ -z "$(dmg2img -d 2>/dev/null)" ]; then
    if [ -z "$(cygcheck -V 2>/dev/null)" ]; then
        echo "Please install the package dmg2img."
        exit
    elif [ -z "$(${PWD}/dmg2img -d 2>/dev/null)" ]; then
        echo "Locally installing dmg2img"
        wget "http://vu1tur.eu.org/tools/dmg2img-1.6.6-win32.zip" \
             ${wgetargs} \
             --output-document="dmg2img-1.6.6-win32.zip"
        if [ ! -s dmg2img-1.6.6-win32.zip ]; then
             echo "Error downloading dmg2img. Please provide the package manually."
             exit
        fi
        unzip -oj "dmg2img-1.6.6-win32.zip" "dmg2img.exe"
        rm "dmg2img-1.6.6-win32.zip"
        chmod +x "dmg2img.exe"
    fi
fi

# Find the correct download URL in the Apple catalog
echo "Searching Apple macOS Mojave software update catalog"
wget 'http://swscan.apple.com/content/catalogs/others/index-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog' \
     ${wgetargs} \
     --output-document='apple.sucatalog.tmp'
echo "Trying to find latest macOS InstallAssistant entry"
tac "apple.sucatalog.tmp" | csplit - '/InstallAssistantAuto.smd/+1' -f "applecatalog.tmp." -s
urlbase="$(tail -n 1 "applecatalog.tmp.00")"
urlbase="$(expr match "${urlbase}" '.*\(http://[^<]*/\)')"
if [ -z "${urlbase}" ]; then
    printf "Couldn't find the download URL in the Apple catalog. Please report this issue
on https://github.com/img2tab/macos-guest-virtualbox/issues
or update the URL yourself from the catalog found
on https://gist.github.com/nuomi1/16133b89c2b38b7eb197
or http://swscan.apple.com/content/catalogs/others/
   index-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog\n"
   exit
fi
echo "Found BaseSystem.dmg URL: ${urlbase}BaseSystem.dmg"
}
# Done with dependencies

# Prompt to delete existing virtual machine config:
function prompt_delete_existing_vm() {
if [ -n "$(VBoxManage showvminfo "${vmname}" 2>/dev/null)" ]; then
    printf '\n"'"${vmname}"'" virtual machine already exists.
'${whiteonred}'Delete existing virtual machine "'"${vmname}"'"?'${defaultcolor}
    delete=""
    read -n 1 -p " [y/n] " delete 2>/dev/tty
    echo ""
    if [ "${delete,,}" == "y" ]; then
        VBoxManage unregistervm "${vmname}" --delete
    else
        printf '\n'${whiteonblack}'Please assign a different VM name to variable "vmname" by editing the script,'${defaultcolor}'
or skip this check manually as described in "'"${0}"' stages".\n'
        exit
    fi
fi
}

# Attempt to create new virtual machine named "${vmname}"
function create_vm() {
if [ -n "$(VBoxManage createvm --name "${vmname}" --ostype "MacOS1013_64" --register 2>&1 1>/dev/null)" ]; then
    printf '\nError: Could not create virtual machine "'"${vmname}"'".
'${whiteonblack}'Please delete exising "'"${vmname}"'" VirtualBox configuration files '${whiteonred}'manually'${defaultcolor}'.

Error message:
'
    VBoxManage createvm --name "${vmname}" --ostype "MacOS1013_64" --register 2>/dev/tty
    exit
fi
}

# Create the macOS base system virtual disk image:
function create_basesystem_vdi() {
if [ -r "BaseSystem.vdi" ]; then
    echo "BaseSystem.vdi bootstrap virtual disk image ready."
else
    echo "Downloading BaseSystem.dmg from swcdn.apple.com"
    wget "${urlbase}BaseSystem.dmg" \
         ${wgetargs} \
         --output-document="BaseSystem.dmg"
    if [ ! -s BaseSystem.dmg ]; then
        printf ${whiteonred}'Could not download BaseSystem.dmg'${defaultcolor}'.'
        exit
    fi
    echo "Downloaded BaseSystem.dmg. Converting to BaseSystem.img"
    if [ -n "$("${PWD}/dmg2img.exe" -d 2>/dev/null)" ]; then
        "${PWD}/dmg2img.exe" "BaseSystem.dmg" "BaseSystem.img"
    else
        dmg2img "BaseSystem.dmg" "BaseSystem.img"
    fi
    VBoxManage convertfromraw --format VDI "BaseSystem.img" "BaseSystem.vdi"
    if [ -s BaseSystem.vdi ]; then
        rm "BaseSystem.dmg" "BaseSystem.img" 2>/dev/null
    fi
fi
}

# Create the target virtual disk image:
function create_target_vdi() {
if [ -w "${vmname}.vdi" ]; then
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
}

# Create the installation media virtual disk image:
function create_install_vdi() {
if [ -w "Install ${vmname}.vdi" ]; then
    echo "Installation media virtual disk image ready."
else
    echo "Creating ${vmname} installation media virtual disk image."
    VBoxManage createmedium --size=12000 \
                            --filename "Install ${vmname}.vdi" \
                            --variant fixed 2>/dev/tty
fi
}

# Attach virtual disk images of the base system, installation, and target
# to the virtual machine
function attach_initial_storage() {
VBoxManage storagectl "${vmname}" --add sata --name SATA --hostiocache on
VBoxManage storageattach "${vmname}" --storagectl SATA --port 0 \
           --type hdd --nonrotational on --medium "${vmname}.vdi"
VBoxManage storageattach "${vmname}" --storagectl SATA --port 1 \
           --type hdd --nonrotational on --medium "Install ${vmname}.vdi"
VBoxManage storageattach "${vmname}" --storagectl SATA --port 2 \
           --type hdd --nonrotational on --medium "BaseSystem.vdi"
}

# Configure the VM
function configure_vm() {
VBoxManage modifyvm "${vmname}" --cpus "${cpucount}" --memory "${memorysize}" \
 --vram "${gpuvram}" --pae on --boot1 dvd --boot2 disk --boot3 none \
 --boot4 none --firmware efi --rtcuseutc on --usbxhci on --chipset ich9 \
 --mouse usbtablet --keyboard usb --audiocontroller hda --audiocodec stac9221
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
}

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

# Start the virtual machine. This should take a couple of minutes.
function populate_virtual_disks() {
echo "Starting virtual machine ${vmname}. This should take a couple of minutes."
VBoxManage startvm "${vmname}" 2>/dev/null

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
echo "Downloading macOS Mojave 10.14 installer."

# downloading macOS
kbstring='urlbase="'"${urlbase}"'"; for filename in BaseSystem.chunklist InstallInfo.plist AppleDiagnostics.dmg AppleDiagnostics.chunklist BaseSystem.dmg InstallESDDmg.pkg; do curl -C - "${urlbase}${filename}" -o "/Volumes/'"${vmname}"'/${filename}"; done'
sendkeys
promptterminalready
echo ""
echo "Loading base system onto installer virtual disk"

# Create secondary base system and shut down the virtual machine
kbstring='asr restore --source "/Volumes/'"${vmname}"'/BaseSystem.dmg" --target /Volumes/Install --erase --noprompt'
sendkeys

promptterminalready

kbstring='shutdown -h now'
sendkeys

printf ${whiteonblack}'
Shutting down virtual machine.
Press enter when the virtual machine shutdown is complete.'${defaultcolor}
read -p ""
echo ""
echo "Detaching initial base system and starting virtual machine."
# Detach the original 2GB BaseSystem.vdi
VBoxManage storageattach "${vmname}" --storagectl SATA --port 2 --medium none
}

function prepare_the_installer_app() {
#Boot from "Install.vdi" that contains the 2GB BaseSystem and 10GB free space
echo "The VM will boot from the new base system on the installer virtual disk."
VBoxManage startvm "${vmname}" 2>/dev/null

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
kbstring='shutdown -h now'
sendkeys
printf ${whiteonblack}'
Shutting down virtual machine.
Press enter when the virtual machine shutdown is complete.'${defaultcolor}
read -p ""
}

function start_the_installer_app() {
VBoxManage startvm "${vmname}" 2>/dev/null
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
}

function manually_install_efi_apfs_drivers {
printf ${whiteonblack}'
After the VM boots, press enter when either the Language window'${defaultcolor}'
'${whiteonblack}'or Utilities window is ready.'${defaultcolor}
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
printf 'Safari should be browsing the following URL:

https://github.com/acidanthera/AppleSupportPkg/releases/tag/2.0.4

In the VM, '${whiteonred}'manually'${defaultcolor}' right-click on AppleSupport-v2.0.4-RELEASE.zip
and click '${whiteonblack}'"Download Linked File As..."'${defaultcolor}', then from the dropdown menu
select "'"${vmname}"'" for "Where:", then unbind the mouse cursor from
the virtual machine with the '${whiteonblack}'right control key'${defaultcolor}' or "host key".'
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
promptterminalready

echo ""
echo "Copying open-source APFS drivers to EFI partition"

# move drivers into path on EFI partition
kbstring='mkdir -p "/Volumes/'"${vmname}"'/mount_efi" && mount_msdos /dev/${disks[0]}s1 "/Volumes/'"${vmname}"'/mount_efi" && mkdir -p "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/" && cd "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/" && tar -xf "/Volumes/'"${vmname}"'/AppleSupport-v2.0.4-RELEASE.zip" && cd "Drivers/" && mv *.efi "/Volumes/'"${vmname}"'/mount_efi/EFI/driver/"'
sendkeys
promptterminalready

# create startup.nsh EFI script
echo ""
echo "Creating EFI startup script that searches for boot.efi"
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
}

function detach_installer_vdi() {
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
}

function boot_macos_and_clean_up() {
echo "The VM will boot from the target virtual disk image."
VBoxManage startvm "${vmname}"
echo ""
echo "macOS Mojave 10.14 will now install and start up."
echo ""

# temporary files cleanup
VBoxManage closemedium "BaseSystem.vdi"
VBoxManage closemedium "Install ${vmname}.vdi"
printf 'Temporary files are safe to delete. '${whiteonred}'Delete temporary files?'${defaultcolor}
delete=""
read -n 1 -p " [y/n] " delete 2>/dev/tty
echo ""
if [ "${delete,,}" == "y" ]; then
    rm "BaseSystem.vdi" "Install ${vmname}.vdi"
    rm "apple.sucatalog.tmp" "applecatalog.tmp.00" "applecatalog.tmp.01"
fi

printf 'macOS Mojave 10.14 installation should complete in a few minutes.

After the installation is complete, the virtual disk image may be increased
through VirtualBox, and then the macOS system APFS container size may be
increased. Inside the virtual machine run "sudo diskutil repairDisk disk0"
and then from Disk Utility delete the "Free space" partition, allowing the
macOS system APFS container to take up the available space.

That'\''s it. Enjoy your virtual machine.
'
}

function stages() {
printf '\nUSAGE: '${whiteonblack}${0}' [STAGE]...'${defaultcolor}'

The script is divided into stages that run as separate functions.
Add one or more stage titles to the command line to run the corresponding
function. If the first argument is "stages" all others are ignored.
Some examples:
    "'"${0}"' populate_virtual_disks prepare_the_installer_app"
These stages might be useful by themselves if the VDI files and the VM are
already initialized.
    "'"${0}"' configure_vm"
This stage might be useful after copying an existing VM VDI to a different
VirtualBox installation and having the script automatically configure the VM.

Available stage titles:
    welcome
    check_dependencies
    prompt_delete_existing_vm
    create_vm
    create_basesystem_vdi
    create_target_vdi
    create_install_vdi
    attach_initial_storage
    configure_vm
    populate_virtual_disks
    prepare_the_installer_app
    start_the_installer_app
    manually_install_efi_apfs_drivers
    detach_installer_vdi
    boot_macos_and_clean_up
'
}

if [ -z "${1}" ]; then
    welcome
    check_dependencies
    prompt_delete_existing_vm
    create_vm
    create_basesystem_vdi
    create_target_vdi
    create_install_vdi
    attach_initial_storage
    configure_vm
    populate_virtual_disks
    prepare_the_installer_app
    start_the_installer_app
    manually_install_efi_apfs_drivers
    detach_installer_vdi
    boot_macos_and_clean_up
else
    if [ "${1}" != "stages" ]; then
        check_dependencies
        for argument in "$@"; do ${argument}; done
    else
        stages
    fi
fi
