#!/bin/bash -eu
# Script to inject a preseed onto an Ubuntu Server ISO. If preseed
# is done correctly this will make the ISO install 100% automated.
#
# Copyright 2016 Canonical Ltd.
# Joshua Powers <josh.powers@canonical.com>
#
LOCALE="en_US.UTF-8"
COUNTRY_CODE="us"

if [[ $# != 2 ]]; then
    echo "$0: A preseed file and ISO file are required as input."
    echo "$0: $0 [preseed] [iso]"
    exit 1
fi

if [ "$(file --brief --mime-type "$1")" != "text/plain" ]; then
    echo "$1: Does not appear to be a text/plain file. Are you sure this is a preseed?"
    exit 1
fi

if [ "$(file --brief --mime-type "$2")" != "application/x-iso9660-image" ]; then
    echo "$2: Does not appear to be a application/x-iso9660-image file. Are you sure this is ISO?"
    exit 1
fi

PRESEED=$1
ISO=$2
ISO_DIR="iso"
ISO_NAME_PRESEED="$(basename "${ISO}" ."${ISO##*.}")-preseed.iso"
ISO_PRESEED="user.seed"
ISO_BOOT_CFG="isolinux/isolinux.cfg"
INITRD_DIR="initrd_dir"

function clean_env {
    if [ -d "$ISO_DIR" ]; then
        chmod -R +w "$ISO_DIR"
        rm -rf "$ISO_DIR"
    fi

    rm -rf "$INITRD_DIR" initrd.fakeroot initrd.old
}
trap clean_env EXIT

# extract ISO
clean_env
mkdir -p "$ISO_DIR"
bsdtar xfp "$ISO" -C "$ISO_DIR"

# inject preseed
chmod +w "$ISO_DIR"
cp "$PRESEED" "$ISO_DIR"/"$ISO_PRESEED"

# modify boot for auto boot with preseed and other options
chmod +w "$ISO_DIR"/"$ISO_BOOT_CFG"
cat <<EOF > "$ISO_DIR"/"$ISO_BOOT_CFG"
path
default vesamenu.c32
default install
label install
  menu label ^Install Ubuntu Server with User Preseed
  kernel /install/vmlinuz
  append  file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/initrd.gz locale=$LOCALE console-setup/ask_detect=false keymap=$COUNTRY_CODE debian-installer/keymap=$COUNTRY_CODE console-setup/layoutcode=$COUNTRY_CODE auto file=/cdrom/$ISO_PRESEED
EOF

# Pull out kernel 
if [ -s  "$ISO_DIR"/install/vmlinuz ]; then
  cp "$ISO_DIR"/install/vmlinuz kernel
elif [[ -s  "$ISO_DIR"/install/vmlinux ]]; then
  cp "$ISO_DIR"/install/vmlinux kernel
fi

# Pull out initrd and inject preseed there as well
cp "$ISO_DIR"/install/initrd.gz initrd.old
mkdir "$INITRD_DIR"
pushd "$INITRD_DIR"
zcat ../initrd.old | fakeroot -s ../initrd.fakeroot cpio -i
cp ../"$PRESEED" preseed.cfg
find | fakeroot -i ../initrd.fakeroot cpio -o -H newc | gzip -c > ../initrd
popd
rm -rf "$INITRD_DIR" initrd.fakeroot initrd.old

# generate new ISO
chmod +w "$ISO_DIR"/isolinux/isolinux.bin
genisoimage -o "$ISO_NAME_PRESEED" -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ./"$ISO_DIR"

echo "Injected '$PRESEED' into initrd"
echo "Injected '$PRESEED' into '$ISO', created '$ISO_NAME_PRESEED'"
