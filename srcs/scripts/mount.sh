
echo "Mounting $LFS_IMG..."
mkdir -p $LFS

if [ -f /persist/format-disk.lock ]; then
	echo "Formatting..."
	DISK=$(cat /persist/format-disk.lock)
	mkfs.vfat -n LFS_EFI  "$DISK"1
	mkfs.ext4 -L LFS_BOOT "$DISK"2
	mkswap    -L LFS_SWAP "$DISK"3
	mkfs.ext4 -L LFS_ROOT "$DISK"4
	rm /persist/format-disk.lock
fi

if [ ! "$HOST_USER" = "root" ]; then
	guestmount -o allow_other -o uid=$(id -u lfs) -o gid=$(id -g lfs) -a $LFS_IMG -m /dev/sda4:/ -m /dev/sda2:/boot -m /dev/sda1:/boot/efi --rw $LFS && \
	echo "Mount successfully!"
else
	chown lfs:lfs $LFS_IMG
	# mount "$LFS_LOOP"p4 $LFS && \
	# mkdir -p $LFS/boot && \
	# mount "$LFS_LOOP"p2 $LFS/boot && \
	# mkdir -p $LFS/boot/efi && \
	# mount "$LFS_LOOP"p1 $LFS/boot/efi && \
	echo "Mount successfully!"
fi

mkdir -p $LFS/tools $LFS/sources
chmod -v a+wt $LFS/sources
chown lfs:lfs -R $LFS/sources $LFS/tools
