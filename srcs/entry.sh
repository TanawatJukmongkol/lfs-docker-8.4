echo "> Chown /persist, /home/lfs, and /mnt to lfs user"
chown -R lfs:lfs /persist
chown -R lfs:lfs /home/lfs

echo "> Generate userspace defaults..."
su lfs -c "bash ./srcs/scripts/userspace_default.sh"

echo "> Install symlinks..."
bash ./srcs/scripts/symlink.sh

echo "> Create image..."
su lfs -c "bash ./srcs/scripts/init_img.sh"

echo "$ SHELL"
source ./srcs/scripts/mount.sh
su lfs
source ./srcs/scripts/umount.sh
