set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
CARGO_TARGET_DIR=~/build

export LFS LC_ALL LFS_TGT PATH CARGO_TARGET_DIR
