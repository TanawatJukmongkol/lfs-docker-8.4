echo "> Chown /persist, /home/lfs, and /mnt to lfs user"
chown -R lfs:lfs /persist
chown -R lfs:lfs /home/lfs

echo "> Generate user space defaults..."
su lfs -c "bash ./srcs/scripts/userspace_default.sh"

echo "> Install symlinks..."
bash ./srcs/scripts/symlink.sh

echo "> User space scripts"
su lfs -c "bash ./srcs/scripts/userspace.sh"

echo "> Chown /home/lfs/srcs back to root"
chown -R root:root /home/lfs/srcs

echo "$ SHELL"
bash ./srcs/scripts/mount.sh
su lfs
bash ./srcs/scripts/umount.sh
