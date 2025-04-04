
if [ "$HOST_USER" = "root" ]; then
    # qemu-nbd -c /dev/nbd0 ./persist/home/lfs/build/lfs.qcow2
    umount $LFS/boot/efi
    umount $LFS/boot
    umount $LFS
else
    echo "Unmounting $LFS_IMG..."
    guestunmount $LFS && \
    echo "Unmount successfully!"
fi
