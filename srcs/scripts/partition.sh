
guestfish -a "$LFS_IMG" << EOF
run
part-init /dev/sda gpt
part-add /dev/sda p 2048 1050624
mkfs vfat /dev/sda1
part-add /dev/sda p 1050625 2099201
mkfs ext4 /dev/sda2
part-add /dev/sda p 2099202 6293506
mkswap /dev/sda3
part-add /dev/sda p 6293507 -2048
mkfs ext4 /dev/sda4
mount /dev/sda4 /
mkdir /boot
mount /dev/sda2 /boot
mkdir /boot/efi
mount /dev/sda1 /boot/efi
label /dev/sda1 LFS_EFI
label /dev/sda2 LFS_BOOT
label /dev/sda4 LFS_ROOT
label /dev/sda3 LFS_SWAP
EOF

