
# guestfish -a "$LFS_IMG" << EOF
# run
# part-init /dev/sda gpt
# part-add /dev/sda p 2048 1050624
# mkfs vfat /dev/sda1
# part-add /dev/sda p 1050625 2099201
# mkfs ext4 /dev/sda2
# part-add /dev/sda p 2099202 6293506
# mkswap /dev/sda3
# part-add /dev/sda p 6293507 -2048
# mkfs ext4 /dev/sda4
# mount /dev/sda4 /
# mkdir /boot
# mount /dev/sda2 /boot
# mkdir /boot/efi
# mount /dev/sda1 /boot/efi
# EOF

guestfish -a "$LFS_IMG" << EOF
run
part-init /dev/sda gpt
part-add /dev/sda p 2048 1050624
part-add /dev/sda p 1050625 2099201
part-add /dev/sda p 2099202 6293506
part-add /dev/sda p 6293507 -2048
EOF

echo "/dev/sda" > /persist/format-disk.lock
