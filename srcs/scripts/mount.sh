
echo "Mounting $LFS_IMG..."
guestmount -a $LFS_IMG -m /dev/sda4:/ -m /dev/sda2:/boot -m /dev/sda1:/boot/efi --rw $LFS && \
echo "Mount successfully!"
