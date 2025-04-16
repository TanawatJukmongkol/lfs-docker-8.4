
# echo "Changing owner on /tools to root user..."

# sudo chown -R root:root $LFS/tools

echo "Creating initial device nodes..."

sudo mkdir -pv $LFS/{dev,proc,sys,run}

sudo mknod -m 600 $LFS/dev/console c 5 1
sudo mknod -m 666 $LFS/dev/null c 1 3

echo "Mount and bind system devices..."

sudo mount -v --bind /dev $LFS/dev

sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  sudo mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

sudo chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
	LFS_ARCH=$LFS_ARCH \
    /tools/bin/bash --login +h

echo "Unmount and unbind system devices..."
sudo umount -v -R $LFS/dev/pts
sudo umount -v -R $LFS/dev
sudo umount -v $LFS/proc
sudo umount -v $LFS/sys
sudo umount -v $LFS/run
