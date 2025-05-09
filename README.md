# Void Linux with encryption on the Rasbperry Pi 4


## TLDR

This is a install script that will setup a Void Linux install with a encrypted root partition and encrypted swap. Just download the script and run it as root.

```bash
sudo ./install.sh
```

Currently this script only works assuming your running Void Linux on a X86 system and installing onto a SD card.

## Acknowledgements

I couldn't have done this without all the amazing info on these two sites, show them some love!

- [https://rr-developer.github.io/LUKS-on-Raspberry-Pi/](https://rr-developer.github.io/LUKS-on-Raspberry-Pi/)
- [https://plantroon.com/voidlinux-encrypted-raspberry-pi/](https://plantroon.com/voidlinux-encrypted-raspberry-pi/)

## To Do
- Allow less memory to be sued in LUKS password hashing so the script will work on other RPI boards.
- Add hooks so the initramfs is regenerated each time the full kernel updates.
- Add the option for different file systems like BTRFS.
- Make the script work on all popular linux distros (Debian, Arch, etc).
