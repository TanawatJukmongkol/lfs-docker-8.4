
HOSTNAME=tjukmong
GRUB_ID="GRUB"
KERNEL_VER="4.20.12"
TARGET_ARCH="x86_64-efi"
ROOT_DEV=$(mount | grep "on / " | awk '{print $1}')

INSTALL_CMD="grub-install \
"$ROOT_DEV" \
--bootloader-id='$GRUB_ID' \
--target='$TARGET_ARCH' \
--efi-directory=/boot/efi \
--recheck"

echo $INSTALL_CMD
sh -c "$INSTALL_CMD"

cat > /boot/grub/grub.cfg << EOF
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

function load_video {
  insmod efi_gop
  insmod efi_uga
  insmod ieee1275_fb
  insmod vbe
  insmod vga
  insmod video_bochs
  insmod video_cirrus
}

insmod ext2
set root=(hd0,2)

if loadfont unicode ; then
  set gfxmode=auto
  load_video
  insmod gfxterm
fi

# terminal_output gfxterm
set timeout=5

menuentry "GNU/Linux, Linux $KERNEL_VER-$HOSTNAME" {
  load_video
  insmod gzio
  insmod part_gpt
  linux   /vmlinuz-$KERNEL_VER-$HOSTNAME root=LABEL=LFS_ROOT rw rootwait noinitrd
}
EOF

