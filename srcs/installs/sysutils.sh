#!/usr/bin/env bash

source $(dirname "$0")/utils.sh

BUILD_DIR=/persist/home/lfs/build/sysutils/
SRC_DIR=/mnt/lfs/sources/
BUILD_JOBS=16

mkdir -p $BUILD_DIR

wget_list << EOF
https://downloads.sourceforge.net/tcl/tcl8.6.9-src.tar.gz
https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz
http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.2.tar.gz
http://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz
http://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz
http://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz
http://ftp.gnu.org/gnu/bison/bison-3.3.2.tar.xz
http://anduin.linuxfromscratch.org/LFS/bzip2-1.0.6.tar.gz
http://ftp.gnu.org/gnu/coreutils/coreutils-8.30.tar.xz
http://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz
ftp://ftp.astron.com/pub/file/file-5.36.tar.gz
http://ftp.gnu.org/gnu/findutils/findutils-4.6.0.tar.gz
http://ftp.gnu.org/gnu/gawk/gawk-4.2.1.tar.xz
http://ftp.gnu.org/gnu/gettext/gettext-0.19.8.1.tar.xz
http://ftp.gnu.org/gnu/grep/grep-3.3.tar.xz
http://ftp.gnu.org/gnu/gzip/gzip-1.10.tar.xz
http://ftp.gnu.org/gnu/make/make-4.2.1.tar.bz2
http://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz
https://www.cpan.org/src/5.0/perl-5.28.1.tar.xz
https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz
http://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz
http://ftp.gnu.org/gnu/tar/tar-1.31.tar.xz
http://ftp.gnu.org/gnu/texinfo/texinfo-6.5.tar.xz
https://www.kernel.org/pub/linux/utils/util-linux/v2.33/util-linux-2.33.1.tar.xz
https://tukaani.org/xz/xz-5.2.4.tar.xz
EOF

install_package tcl8.6.9-src.tar.gz << EOF

cd unix
./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# TZ=UTC make test

make install

chmod -v u+w /tools/lib/libtcl8.6.so

make install-private-headers

ln -sv tclsh8.6 /tools/bin/tclsh

EOF

install_package expect5.45.4.tar.gz << EOF

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make -j$BUILD_JOBS $MAKE_FLAGS

# make test

make SCRIPTS="" install

EOF

install_package dejagnu-1.6.2.tar.gz << EOF

./configure --prefix=/tools

make install

# make check

EOF

install_package m4-1.4.18.tar.xz << EOF

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package ncurses-6.1.tar.gz << EOF

sed -i s/mawk// configure

./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make -j$BUILD_JOBS $MAKE_FLAGS

make install
ln -s libncursesw.so /tools/lib/libncurses.so

EOF

install_package bash-5.0.tar.gz << EOF

./configure --prefix=/tools --without-bash-malloc

make -j$BUILD_JOBS $MAKE_FLAGS

# make tests

make install

ln -sv bash /tools/bin/sh

EOF

install_package bison-3.3.2.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package bzip2-1.0.6.tar.gz << EOF

make -j$BUILD_JOBS $MAKE_FLAGS

make PREFIX=/tools install

EOF

install_package coreutils-8.30.tar.xz << EOF

./configure --prefix=/tools --enable-install-program=hostname

make -j$BUILD_JOBS $MAKE_FLAGS

# make RUN_EXPENSIVE_TESTS=yes check

make install

EOF

install_package file-5.36.tar.gz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package findutils-4.6.0.tar.gz << EOF

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package gawk-4.2.1.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package gettext-0.19.8.1.tar.xz << EOF

cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared

make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

EOF

install_package grep-3.3.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package gzip-1.10.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package make-4.2.1.tar.bz2 << EOF

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/tools --without-guile

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package patch-2.7.6.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package perl-5.28.1.tar.xz << EOF

sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth

make -j$BUILD_JOBS $MAKE_FLAGS

cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.28.1
cp -Rv lib/* /tools/lib/perl5/5.28.1

EOF

install_package Python-3.7.2.tar.xz << EOF

sed -i '/def add_multiarch_paths/a \        return' setup.py

./configure --prefix=/tools --without-ensurepip

make -j$BUILD_JOBS $MAKE_FLAGS

make install

EOF

install_package sed-4.7.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package tar-1.31.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package texinfo-6.5.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

install_package util-linux-2.33.1.tar.xz << EOF

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""

make -j$BUILD_JOBS $MAKE_FLAGS

make install

EOF

install_package xz-5.2.4.tar.xz << EOF

./configure --prefix=/tools

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make install

EOF

# echo "Stripping unused files..."
#
# strip --strip-debug /tools/lib/*
# /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
#
# rm -rf /tools/{,share}/{info,man,doc}
#
# find /tools/{lib,libexec} -name \*.la -delete

