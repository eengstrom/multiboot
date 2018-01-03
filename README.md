# Creation/Curation of Multiboot USB Stick or SD card or ...

## Creation

First step is to create a bootable device, in my case a system embedded sd card, but works equally well 
for a USB stick.

    $ lsblk -d -io KNAME,TYPE,SIZE,MODEL
    KNAME TYPE   SIZE MODEL
    ....
    sdb   disk   972M Internal Dual SD

    $ parted /dev/sdX
      > mklabel msdos
      > mkpart primary fat32 1 100%
      > set 1 boot on
      > quit

    $ mkfs -t vfat /dev/sdX1  # or -t fat32
    $ mkdir /tmp/multiboot
    $ mount /dev/sdX1 /mnt/multiboot
    $ grub-install --force --no-floppy --root-directory=/mnt/multiboot /dev/sdX
  
  Note that I tried FS type EXFAT, but that caused grief with some
  distros - error about "unknown file system type" on boot (from iso).

Then, setup the file system structure (arbitrary, but cleaner, IMO)

    $ cd /mnt/multiboot
    $ mkdir iso
    $ wget -nc -o iso/DISTRO.iso http://..../<DISTRO>.iso 

As an example for Ubuntu 16.04, you can fetch:

    http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/mini.iso 

## Curation

Once you've got it started, just add new iso(s) to your `iso` subdir and edit `grub.cfg`.  When you first get started, chances are there is NOTHING (or no file) for your `/mnt/multiboot/boot/grub/grub.cfg`, but if there is, modify it to suit your distro needs, but here is an mini example to get you started (or see [my current full one](boot/grub/grub.cfg)):

    # Timeout for menu
    set timeout=60
    
    # Default boot entry
    set default=0
    
    # Menu Colours
    set menu_color_normal=white/black
    set menu_color_highlight=white/green

    # 9.x/Stretch: http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/
    menuentry "Debian 9.x/Stretch - AMD64 Mini/Netboot-Installer" {
        set iso="/iso/debian-9.x-amd64-mini.iso"
        loopback loop $iso
        linux (loop)/linux
        initrd (loop)/initrd.gz
    }
  
    # 16.x Xenial LTS - https://help.ubuntu.com/community/Installation/MinimalCD
    menuentry "Ubuntu 16.04/Xenial LTS - 64bit Mini-Installer" {
        set iso="/iso/ubuntu-16.04-mini-amd64.iso"
        loopback loop $iso
        linux (loop)/linux boot=casper iso-scan/filename=$iso noprompt noeject
        initrd (loop)/initrd.gz
    }

The main trick is the use of the `loopback` directive to directly use the iso, but other directives to the linux kernel may be required, such as `iso-scan/opt=xxx`.  Unfortuantely, it's still a bit more of an art to know what's in the `initrd` image to know what things you can use to ensure the kernel has all the required bits.  Also, sometimes it's helpful to examine the `grub.cfg` inside iso itself (which is otherwise **not** used in this setup) to see what options are typically passed to the kernel on boot.

## Cleanup:
    
    # simplify future editing of grub with symlink to "root".
    # works on Mac - unsure of magic.
    # .. but not on Linux, since FAT* fs can't do symlinks.
    $ cd /mnt/multiboot
    $ ln -s boot/grub/grub.cfg /mnt/multiboot/grub.cfg
    # unmount the device
    $ cd /mnt
    $ umount /mnt/multiboot

# Notes / Links

Original idea came from http://www.circuidipity.com/multi-boot-usb.html, with other tips or ideas from:

  - https://help.ubuntu.com/community/Grub2/ISOBoot  (includes ideas to make it UEFI compatible)
  - https://help.ubuntu.com/community/Grub2/ISOBoot/Examples
  - http://askubuntu.com/questions/388382/multi-partition-multi-os-bootable-usb (UEFI notes)
  - https://wiki.archlinux.org/index.php/Multiboot_USB_drive
  - http://www.pendrivelinux.com/multiboot-create-a-multiboot-usb-from-linux/
  - https://github.com/thias/glim
  - http://chtaube.eu/computers/freedos/bootable-usb/
  - https://wdullaer.com/blog/2010/02/26/boot-iso-files-from-usb-with-grub4dos/ (using `grub4dos`)

## Mounting ISO on (Mac) OSX, e.g. to examine embedded grub.cfg ([source][2]):

    hdiutil attach -nomount DIST.iso
    mkdir /tmp/DIST
    mount -t cd9660 /dev/diskX /tmp/DIST
    less /tmp/DIST/boot/grub/grub.cfg
    ...
    umount /tmp/DIST
    hdiutil detach diskX

[2]: https://unix.stackexchange.com/questions/298685/can-a-mac-mount-a-debian-install-cd
[3]: http://rentageekla.com/2010/10/27/how-to-mount-an-iso-that-contains-multiple-partitions/
