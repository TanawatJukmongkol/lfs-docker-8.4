echo "> Chown /persist"
chown -R lfs /persist

echo "> Generate user space defaults..."
su lfs -c "bash ./srcs/scripts/userspace_default.sh"

echo "> Install symlinks..."
bash ./srcs/scripts/symlink.sh

echo "> User space scripts"
su lfs -c "bash ./srcs/scripts/userspace.sh"

echo "$ SHELL"
su lfs