#!/bin/bash
# Create from scratch a multiboot (removable) device with grub installed.

# DANGER WILL ROBINSON - this is not for the weak minded - it does
# what __I__ want it to, but hey, if you use it wrong, you could
# totally F***-UP your host, so, use completely at your own risk.
#
# See LICENCE file for more formal language, but essentially, 
# please don't blame me for any damage to any computer system.
## 

set -e
#set -x

SUDO=sudo
#SUDO=echo

SHORTNAME=multiboot
PROGNAME=$(basename "$0")
warn()  { echo "$PROGNAME: ${@}" 1>&2; }
die()   { warn "${@}" 1>&2; exit 1; }
debug() { test -n "$DEBUG" && echo "DEBUG: ${@}" 1>&2; }
#usage() { echo "usage: $PROGNAME [USER@]HOST[:PATH] [MOUNT]" 1>&2; }

[[ `id -u` -eq 0 ]] \
 && die "ERROR: Don't run as root; run as user with sudo access."

#read -n 1 -s -p "Install for EFI in addition to standard BIOS? (Y/n) " EFI

# Show and pick device
echo "Available devices:"
lsblk -d -io KNAME,TYPE,SIZE,MODEL
read -p "Select device: " DEV

DEV=/dev/$DEV
PRT=${DEV}1
MNT=/mnt/${SHORTNAME}
ISO=${MNT}/iso

# Test if the block device exists (user mistype error)
test -b $DEV || die "Device '$DEV' is not a block device."

# Warn the user and get confirmation
printf "\nWARNING: About to DESTORY all contents on '${DEV}':\n"
lsblk $DEV
echo
read -p "PROCEED with caution: type :YES: to continue: " CONFIRM
[[ ${CONFIRM} == "YES" ]] || exit 

# Do the rest.
$SUDO umount ${DEV}* 2>/dev/null || true

$SUDO parted -s ${DEV} mklabel msdos \
                       mkpart primary fat32 1 100% \
                       set 1 boot on \
                       print

# Partial start on GPT/EFI version:
#$SUDO parted -s ${DEV} mklabel gpt \
#                       mkpart MULTIBOOT fat32 1 100% \
#                       set 1 boot on \
#                       print

# odd, but if I don't wait a bit, the new partition/device is not "available".
sleep 1

$SUDO mkfs -t vfat ${PRT}
$SUDO mkdir -p ${MNT}
$SUDO mount ${PRT} ${MNT}
$SUDO grub-install --force --recheck --no-floppy --boot-directory=${MNT} ${DEV}

# setup directory structure, copy grub config and iso(s)
$SUDO mkdir -p ${ISO}
$SUDO rsync -rv --size-only --no-perms --exclude='.git*' --progress grub iso ${MNT}/

printf "\nComplete.  New bootable device mounted at '${MNT}':\n"
df | grep -i $SHORTNAME
(set -x; ls -F ${MNT}; ls -F ${ISO})

#$SUDO umount ${MNT}

##
