
BUILD=${LFS_BUILD}
IMG_DIR="${BUILD}/dist"
IMG_TYPE="qcow2"
IMG_PATH="${IMG_DIR}/lfs.${IMG_TYPE}"
IMG_SIZE="25G"

if [ "$HOST_USER" = "root" ]; then
    exit
fi

# Generate disk image
if [ ! -f "$LFS_IMG" ]; then
    echo "> Creating qcow2 disk image..."
    mkdir -p "${IMG_DIR}"
    qemu-img create -f ${IMG_TYPE} ${IMG_PATH} ${IMG_SIZE}
    sleep 1
    echo "> Partitioning..."
    bash ~/srcs/scripts/partition.sh
fi
