echo "Unmounting $LFS_IMG..."

if [ ! "$HOST_USER" = "root" ]; then
    guestunmount $LFS && \
    echo "Unmount successfully!"
else
	umount $LFS/boot/efi && \
	umount $LFS/boot && \
	umount $LFS && \
	qemu-nbd -d $LFS_LOOP && \
	echo "Unmount successfully!"
fi
