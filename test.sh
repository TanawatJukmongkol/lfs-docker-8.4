grub-install /dev/sda --bootloader-id='GRUB' --target='x86_64-efi' --efi-directory=$LFS/boot/efi --boot-directory=$LFS/boot --root-directory=$LFS --recheck

TODO:
 - Change from create and format disk to create and then format AFTER entry.sh
 - Fix guestmount disk lable