
mkdir -p $LFS

if [ "$HOST_USER" = "root" ]; then
    # qemu-nbd -c /dev/nbd0 ./persist/home/lfs/build/lfs.qcow2
    mount /dev/nbd0p4 $LFS
    mount /dev/nbd0p2 $LFS/boot
    mount /dev/nbd0p1 $LFS/boot/efi
else
    echo "Mounting $LFS_IMG..."
    guestmount -o allow_other -a $LFS_IMG -m /dev/sda4:/ -m /dev/sda2:/boot -m /dev/sda1:/boot/efi --rw $LFS && \
    echo "Mount successfully!"
fi

mkdir -p $LFS/tools $LFS/sources
