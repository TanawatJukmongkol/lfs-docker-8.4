set +h
umask 022
LC_ALL=POSIX
PATH=/tools/bin:/bin:/usr/bin

CARGO_TARGET_DIR=~/build
GUESTFISH_TMPDIR=$HOME/tmp
LFS_IMG=/home/lfs/build/lfs.qcow2

export \
LC_ALL PATH \
CARGO_TARGET_DIR \
GUESTFISH_TMPDIR \
