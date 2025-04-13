echo "Unmounting $LFS_IMG..."

umount -q -R $LFS/dev/pts
umount -q -R $LFS/dev
umount -q $LFS/proc
umount -q $LFS/sys
umount -q $LFS/run

if [ ! "$HOST_USER" = "root" ]; then
    guestunmount $LFS && \
    echo "Unmount successfully!"
else
	umount $LFS/boot/efi && \
	umount $LFS/boot && \
	umount $LFS && \
	echo "Unmount successfully!"
fi
