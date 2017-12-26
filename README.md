Creation/Curation of Multiboot USB Stick or SD card or ...

# Creation

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

Chances are there is NOTHING (or no file) for your `/mnt/multiboot/boot/grub/grub.cfg`, but if there is, modify it to suit your distro needs, but here is an mini example to get you started (or [my current full one](multiboot.cfg)):

    # Idea from: 
    # - http://www.circuidipity.com/multi-boot-usb.html

    # Timeout for menu
    set timeout=60
    
    # Default boot entry
    set default=0
    
    # Menu Colours
    set menu_color_normal=white/black
    set menu_color_highlight=white/green

    # Typical recipe for linux-flavored isos:
    # - vmlinuz : add findiso=$iso to end

    # ---- UBUNTU ----
    submenu 'Ubuntu GNU/Linux' {
      # 16.x Xenial LTS - https://help.ubuntu.com/community/Installation/MinimalCD
      menuentry "Ubuntu 16.04/Xenial LTS - 64bit Mini-Installer" {
          set iso="/iso/ubuntu-16.04-mini-amd64.iso"
          loopback loop $iso
          linux (loop)/linux boot=casper iso-scan/filename=$iso noprompt noeject
          initrd (loop)/initrd.gz
      }
    }

Cleanup:
    
    # simplify future editing of grub with symlink to "root"
    # works on Mac - unsure of magic - but not on most Linux-en:
    $ ln -s boot/grub/grub.cfg /mnt/multiboot/grub.cfg
    # unmount the device
    $ cd /mnt
    $ umount /mnt/multiboot


# Footnotes

Original idea came from http://www.circuidipity.com/multi-boot-usb.html, with other tips or ideas from:

  - http://askubuntu.com/questions/388382/multi-partition-multi-os-bootable-usb
  - http://www.pendrivelinux.com/multiboot-create-a-multiboot-usb-from-linux/
  - http://www.pendrivelinux.com/yumi-multiboot-usb-creator/
  - http://www.pendrivelinux.com/xboot-multiboot-iso-usb-creator/
  - http://www.pendrivelinux.com/universal-usb-installer-easy-as-1-2-3/

# Edit `[[file:boot/grub/grub.cfg][/boot/grub/grub.cfg]]` to add new entries
# FreeDos bootable USB:
http://chtaube.eu/computers/freedos/bootable-usb/
# Other related
http://rentageekla.com/2010/10/27/how-to-mount-an-iso-that-contains-multiple-partitions/
