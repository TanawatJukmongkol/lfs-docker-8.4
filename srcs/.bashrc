set +h
umask 022
LC_ALL=POSIX
PATH=/tools/bin:/bin:/usr/bin

CARGO_TARGET_DIR=~/build
GUESTFISH_TMPDIR=$HOME/tmp
LFS_IMG=/home/lfs/build/lfs.qcow2

BUILD_JOBS=$(( $( nproc ) * 3 / 2 ))
MAKE_FLAGS="-l $( nproc )"

export \
LC_ALL PATH \
CARGO_TARGET_DIR \
GUESTFISH_TMPDIR \
BUILD_JOBS \
MAKE_FLAGS