
HOSTNAME=tjukmong
GRUB_ID="GRUB"
KERNEL_VER="4.20.12"
TARGET_ARCH="x86_64-efi"
ROOT_DEV=$(mount | grep "on / " | awk '{print $1}')

BUILD_JOBS=$(( $( nproc ) * 3 / 2 ))
MAKE_FLAGS="-l $( nproc )"

INSTALL_CMD="grub-install \
--bootloader-id='$GRUB_ID' \
--target='$TARGET_ARCH' \
--efi-directory=/boot/efi \
--boot-directory=/boot \
--recheck"

echo $INSTALL_CMD
sh -c "$INSTALL_CMD"

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux $KERNEL_VER-$HOSTNAME" {
        linux   /boot/vmlinuz-$KERNEL_VER-$HOSTNAME root=LABEL=LFS_ROOT rw rootwait noinitrd
}
EOF

