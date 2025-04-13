
if [ "$HOST_USER" = "root" ]; then
    exit
fi

# Generate disk image
if [ ! -f "$LFS_IMG" ]; then
    echo "> Creating qcow2 disk image..."
    qemu-img create -f qcow2 "$LFS_IMG" 25G
    sleep 1
    echo "> Partitioning..."
    bash ~/srcs/scripts/partition.sh
fi
