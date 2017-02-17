# Ubuntu Server Preseed
Takes a given preseed and injects it into a given Ubuntu Server ISO (without sudo)

To obtain and run:

```
wget https://raw.githubusercontent.com/powersj/ubuntu-server-preseed/master/inject_preseed.sh
chmod +x inject_preseed.sh 
./inject_preseed.sh [preseed] [iso]
```

Where `[preseed]` is a text file containing the preseed options you wish to use and `[iso]` is an ISO file to inject the preseed into.

## Preseed
There is a fully automated preseed example in `preseed.cfg`.

If you want something other than those defaults you will need to consult the [Ubuntu Preseed Example](https://help.ubuntu.com/lts/installation-guide/example-preseed.txt). That link has examples and inline documentation for all possible values.

## Testing
Once you generate a new ISO, you can run a quick test by running:

```
qemu-img create -f qcow2 vdisk.img 4G 
qemu-system-x86_64 -enable-kvm  -cpu host -m 1024 -boot d -hda vdisk.img -cdrom [NEW_ISO_HERE]
```

Or if you wish to boot with the kernel and initrd directly to allow passing kernel paramters directly:

```
qemu-img create -f qcow2 vdisk.img 4G 
qemu-system-x86_64 -enable-kvm -cpu host -m 1024 -boot d \
    -initrd initrd -kernel kernel \
    -append 'console=ttyS0 priority=critical' \
    -display none -nographic \
    -hda vdisk.img \
    -cdrom [NEW_ISO_HERE]
```

## Locale and Country Code
Locale and country code can be changed in the `inject_preseed.sh` file. At the top change them to your required values:

```
LOCALE="en_US.UTF-8"
COUNTRY_CODE="us"
```

To see a list of supported locale on a running system run `cat /usr/share/i18n/SUPPORTED`.

To see a list of supported country codes on a running system run `cat /usr/share/zoneinfo/iso3166.tab`.
