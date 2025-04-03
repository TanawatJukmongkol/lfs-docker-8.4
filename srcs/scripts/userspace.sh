
# Generate disk image
if [ ! -f ~/build/lfs.qcow2 ]; then
    qemu-img create -f qcow2 ~/build/lfs.qcow2 20G
fi
