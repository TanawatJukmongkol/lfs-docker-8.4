
echo "Mounting $LFS_IMG..."
guestmount -a build/lfs.qcow2 -m /dev/sda4:/ -m /dev/sda2:/boot -m /dev/sda1:/boot/efi --rw /mnt && \
echo "Mount successfully!"
