
# Generate disk image
if [ ! -f "./$LFS_IMG" ]; then

BUILD=./${LFS_BUILD}
IMG_DIR="${BUILD}/dist"
IMG_TYPE="qcow2"
IMG_PATH="${IMG_DIR}/lfs.${IMG_TYPE}"
IMG_SIZE="25G"

if [ -z "${BUILD}" ]; then
	echo '$BUILD is empty.'
	exit 1
fi

mkdir -p "${IMG_DIR}"

# Create disk image if not present
if [ ! -e "${IMG_PATH}" ]; then
	echo "Creating the disk image..."
	qemu-img create -f ${IMG_TYPE} ${IMG_PATH} ${IMG_SIZE}
else
	echo "Image already exists. Skipping creation."
fi

# Connect NBD
if [ ! -e "${LFS_LOOP}" ]; then
	modprobe nbd max_part=16
fi

echo "Attaching image to NBD..."
qemu-nbd -d ${LFS_LOOP}
qemu-nbd -c ${LFS_LOOP} ${IMG_PATH}
sleep 1

# Use sfdisk for GPT partitioning
echo "Partitioning with sfdisk..."
sfdisk --label gpt ${LFS_LOOP} <<EOF
label: gpt
unit: sectors

${LFS_LOOP}p1 :   start=2048, size=1228800, type=uefi
${LFS_LOOP}p2 : size=1228800, type=linux
${LFS_LOOP}p3 : size=4194304, type=swap
${LFS_LOOP}p4 : type=linux
EOF

# Filesystems
echo "Creating filesystems..."
mkfs.vfat -n LFS_EFI  ${LFS_LOOP}p1
mkfs.ext4 -L LFS_BOOT ${LFS_LOOP}p2
mkswap    -L LFS_SWAP ${LFS_LOOP}p3
mkfs.ext4 -L LFS_ROOT ${LFS_LOOP}p4
sleep 1

# echo "Detaching NBD..."
# qemu-nbd -d ${IMG_LOOPBACK_DISK}
# rmmod nbd

chown :users ${IMG_PATH}

# echo "$LFS_LOOP"p > ./persist/format-disk.lock

else
    qemu-nbd -c ${LFS_LOOP} ./${LFS_IMG};
    sleep 1
fi

mkdir -p ./$LFS
# chown lfs:lfs $LFS_IMG
mount "$LFS_LOOP"p4 ./$LFS && \
mkdir -p ./$LFS/boot && \
mount "$LFS_LOOP"p2 ./$LFS/boot && \
mkdir -p ./$LFS/boot/efi && \
mount "$LFS_LOOP"p1 ./$LFS/boot/efi && \
echo "Mount successfully!"
