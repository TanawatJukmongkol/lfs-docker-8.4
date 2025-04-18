### NEED FIX!!! ###


# TODO: https://www.linuxfromscratch.org/museum/lfs-museum/8.4-systemd/LFS-BOOK-8.4-systemd-HTML/chapter06/revisedchroot.html

sudo chroot "$LFS" /usr/bin/env -i          \
         HOME=/root TERM="$TERM"            \
         PS1='(lfs chroot) \u:\w\$ '        \
         PATH=/bin:/usr/bin:/sbin:/usr/sbin \
/bin/bash --login -x << CHROOT_EOF

## NETWORKING ##

cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=$(ip route get 8.8.8.8 | awk '{print $5}')

[Network]
DHCP=ipv4

[DHCP]
UseDomains=true
EOF

# Generate resolv.conf

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain      $HOSTNAME.42.fr
nameserver  172.19.0.1
nameserver  9.9.9.9

# End /etc/resolv.conf
EOF

echo "$HOSTNAME" > /etc/hostname

cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost
127.0.1.1 $HOSTNAME.42.fr $HOSTNAME
::1       $HOSTNAME.42.fr

# End /etc/hosts
EOF

## TIMEZONE ##
cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

# timedatectl list-timezones

# timedatectl set-local-rtc 1
# timedatectl set-timezone $TIMEZONE

# systemctl disable systemd-timesyncd

## CONSOLE (TTY) ##
cat > /etc/vconsole.conf << "EOF"
KEYMAP=us
# FONT=ter-v32n
EOF

## LOCALE ##

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_TIME=en_US.UTF-8
EOF

## INPUTRC (READLINE) ##

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

## SHELL LISTS ##

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

## SYSTEMD ##

#
mkdir -pv /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF

# Disable tmpfs for /tmp (why tho? tmp should be cleared! tmpfs + swap ftw!)
# ln -sfv /dev/null /etc/systemd/system/tmp.mount

# File create + delete automation (at boot / runtime)
# /usr/lib/tmpfiles.d/tmp.conf

mkdir -p /etc/tempfiles.d
cp /usr/lib/tmpfiles.d/tmp.conf /etc/tempfiles.d

## FSTAB ##

cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

LABEL=LFS_ROOT     /            ext4     defaults            1     1
LABEL=LFS_BOOT     /boot        ext4     defaults            1     2
LABEL=LFS_EFI      /boot/efi    vfat     defaults            1     3
LABEL=LFS_SWAP     swap         swap     pri=1               0     0

# End /etc/fstab
EOF

bash /installs/linux-kernel.sh
bash /installs/grub-install.sh

CHROOT_EOF
