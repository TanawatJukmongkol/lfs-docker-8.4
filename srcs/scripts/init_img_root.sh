
# Generate disk image
if [ ! -f "./$LFS_IMG" ]; then
    mkdir -p ./$LFS_BUILD
    echo "> Creating qcow2 disk image..."
    pwd
    qemu-img create -f qcow2 "./$LFS_IMG" 25G
	qemu-nbd -c ${LFS_LOOP} ./${LFS_IMG};
	sleep 1
    echo "> Partitioning..."
fdisk $LFS_LOOP << EOF
g
n
1
2048
1050624
t
1
n
2
1050625
2099201
n
3
2099202
6293506
t
3
19
n
4
6293507
-2048
w

EOF


sleep 1

# Format EFI partition (vfat)
mkfs.vfat -F32 /dev/nbd0p1

# Format /boot partition
mkfs.ext4 -F /dev/nbd0p2

# Initialize swap
mkswap /dev/nbd0p3

# Format root (/) partition
mkfs.ext4 -F /dev/nbd0p4

else
    qemu-nbd -c ${LFS_LOOP} ./${LFS_IMG};
    sleep 1
fi
