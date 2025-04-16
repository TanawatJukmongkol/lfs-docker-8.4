
#!/usr/bin/env bash

source /installs/utils.sh

BUILD_DIR=/tmp/build/system_build/
SRC_DIR=/sources/

BUILD_JOBS=$(( $( nproc ) * 3 / 2 ))
MAKE_FLAGS="-l $( nproc )"

mkdir -p $BUILD_DIR

install_package linux-4.20.12.tar.xz << EOF
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
EOF

install_package man-pages-4.16.tar.xz << EOF

make install

EOF

install_package glibc-2.29.tar.xz << EOF

patch -Np1 -i $SRC_DIR/glibc-2.29-fhs-1.patch

ln -sfv /tools/lib/gcc /usr/lib

case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac

rm -f /usr/include/limits.h

mkdir -v build
cd       build

CC="gcc -isystem \$GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                           \
             --disable-werror                        \
             --enable-kernel=3.2                     \
             --enable-stack-protector=strong         \
             libc_cv_slibdir=/lib
unset GCC_INCDIR

make -j$BUILD_JOBS $MAKE_FLAGS

case $(uname -m) in
  i?86)   ln -sfnv \$PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv \$PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac

# make check

touch /etc/ld.so.conf

sed '/test-installation/s@\$(PERL)@echo not running@' -i ../Makefile

make -j$BUILD_JOBS $MAKE_FLAGS install

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service

mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

make -j$BUILD_JOBS $MAKE_FLAGS localedata/install-locales

cat > /etc/nsswitch.conf << "LFS_EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
LFS_EOF

tar -xf $SRC_DIR/tzdata2018i.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv \$ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d \$ZONEINFO       \${tz}
    zic -L /dev/null   -d \$ZONEINFO/posix \${tz}
    zic -L leapseconds -d \$ZONEINFO/right \${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab \$ZONEINFO
zic -d \$ZONEINFO -p America/New_York
unset ZONEINFO

# tzselect

export TZ="Asia/Bangkok"
ln -sfv /usr/share/zoneinfo/\$TZ /etc/localtime

cat > /etc/ld.so.conf << "LFS_EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

LFS_EOF

cat >> /etc/ld.so.conf << "LFS_EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

LFS_EOF
mkdir -pv /etc/ld.so.conf.d

EOF

if [ ! -f /tools/bin/ld-old ]; then

mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
./configure --prefix=/usr

fi

# Tests can be found here https://www.linuxfromscratch.org/museum/lfs-museum/8.4-systemd/LFS-BOOK-8.4-systemd-HTML/chapter06/adjusting.html

install_package zlib-1.2.11.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libz.so) /usr/lib/libz.so

EOF

install_package file-5.36.tar.gz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package readline-8.0.tar.gz << EOF

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-8.0

make SHLIB_LIBS="-L/tools/lib -lncursesw" -j$BUILD_JOBS $MAKE_FLAGS
make SHLIB_LIBS="-L/tools/lib -lncursesw" -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/\$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/\$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0

EOF

install_package m4-1.4.18.tar.xz << EOF

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS

# make check

make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package bc-1.07.1.tar.gz << EOF

cat > bc/fix-libmath_h << "LFS_EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
LFS_EOF

ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
ln -sfv libncursesw.so.6 /usr/lib/libncurses.so

sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure

./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info

make -j$BUILD_JOBS $MAKE_FLAGS

# echo "quit" | ./bc/bc -l Test/checklib.b

make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package binutils-2.32.tar.xz << EOF

mkdir -v build
cd       build

../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
--enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make -j$BUILD_JOBS $MAKE_FLAGS tooldir=/usr

# make -k check

make -j$BUILD_JOBS $MAKE_FLAGS tooldir=/usr install

EOF

install_package gmp-6.1.2.tar.xz << EOF

# For 32-bit processer (if host is x86_64, but target is 32bit)
# export ABI=32

# Generic library (if compile target has less-powerful hardware)
cp -v configfsf.guess config.guess
cp -v configfsf.sub   config.sub

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS html

# make check 2>&1 | tee gmp-check-log
# awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

make -j$BUILD_JOBS $MAKE_FLAGS install
make -j$BUILD_JOBS $MAKE_FLAGS install-html

unset ABI

EOF

install_package mpfr-4.0.2.tar.xz << EOF

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.2

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS html

# make check

make -j$BUILD_JOBS $MAKE_FLAGS install
make -j$BUILD_JOBS $MAKE_FLAGS install-html

EOF

install_package mpc-1.1.0.tar.gz << EOF

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS html

# make check

make -j$BUILD_JOBS $MAKE_FLAGS install
make -j$BUILD_JOBS $MAKE_FLAGS install-html

EOF

# Install cracklib here (if you want)

install_package shadow-4.6.tar.xz 1 << EOF

sed -i 's/groups\$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

if [ -d /lib/cracklib ]; then
sed -i 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs
fi

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/passwd /bin

pwconv
grpconv

sed -i 's/yes/no/' /etc/default/useradd

passwd root
# echo "lfs" | passwd root --stdin

EOF

install_package gcc-8.2.0.tar.xz << EOF

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

rm -f /usr/lib/gcc

rm -rf   build
mkdir -v build
cd       build

SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-libmpx         \
             --with-system-zlib

make -j$BUILD_JOBS $MAKE_FLAGS

# ulimit -s 32768
# rm ../gcc/testsuite/g++.dg/pr83239.C
# chown -Rv nobody .
# su nobody -s /bin/bash -c "PATH=\$PATH make -k check"
# ../contrib/test_summary | grep -A7 Summ

make -j$BUILD_JOBS $MAKE_FLAGS install

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/\$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

# Tests are in https://www.linuxfromscratch.org/museum/lfs-museum/8.4-systemd/LFS-BOOK-8.4-systemd-HTML/chapter06/gcc.html

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

EOF

install_package bzip2-1.0.6.tar.gz << EOF

patch -Np1 -i $BUILD_DIR/bzip2-1.0.6-install_docs-1.patch

sed -i 's@\(ln -s -f \)\$(PREFIX)/bin/@\1@' Makefile

sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

EOF

install_package pkg-config-0.29.2.tar.gz << EOF

./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package ncurses-6.1.tar.gz << EOF

sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libncursesw.so.6* /lib

ln -sfv ../../lib/\$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib\${lib}.so
    echo "INPUT(-l\${lib}w)" > /usr/lib/lib\${lib}.so
    ln -sfv \${lib}w.pc        /usr/lib/pkgconfig/\${lib}.pc
done

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so

mkdir -v       /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1

make distclean
./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding \
            --with-abi-version=5

make -j$BUILD_JOBS $MAKE_FLAGS sources libs
cp -av lib/lib*.so.5* /usr/lib

EOF

install_package attr-2.4.48.tar.gz << EOF

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

EOF

install_package acl-2.2.53.tar.gz << EOF

./configure --prefix=/usr         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

EOF

install_package libcap-2.26.tar.xz << EOF

sed -i '/install.*STALIBNAME/d' libcap/Makefile

make -j$BUILD_JOBS $MAKE_FLAGS

make -j$BUILD_JOBS $MAKE_FLAGS RAISE_SETFCAP=no lib=lib prefix=/usr install
chmod -v 755 /usr/lib/libcap.so.2.26

mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

EOF

install_package sed-4.7.tar.xz << EOF

sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in

./configure --prefix=/usr --bindir=/bin

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS html

make -j$BUILD_JOBS $MAKE_FLAGS install
install -d -m755           /usr/share/doc/sed-4.7
install -m644 doc/sed.html /usr/share/doc/sed-4.7

EOF

install_package psmisc-23.2.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

EOF

install_package iana-etc-2.30.tar.bz2 << EOF

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package bison-3.3.2.tar.xz << EOF

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.3.2

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package flex-2.6.4.tar.gz << EOF

sed -i "/math.h/a #include <malloc.h>" src/flexdef.h

HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

ln -sv flex /usr/bin/lex

EOF

install_package grep-3.3.tar.xz << EOF

./configure --prefix=/usr --bindir=/bin

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package bash-5.0.tar.gz << EOF

./configure --prefix=/usr                    \
            --docdir=/usr/share/doc/bash-5.0 \
            --without-bash-malloc            \
            --with-installed-readline

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install
mv -vf /usr/bin/bash /bin

EOF

# exec /bin/bash --login +h

install_package libtool-2.4.6.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package gdbm-1.18.1.tar.gz << EOF

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package gperf-3.1.tar.gz << EOF

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package expat-2.2.6.tar.bz2 << EOF

sed -i 's|usr/bin/env |bin/|' run.sh.in

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.6

EOF

install_package inetutils-1.9.4.tar.xz << EOF

./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

EOF

install_package perl-5.28.1.tar.xz << EOF

echo "127.0.0.1 localhost \$(hostname)" > /etc/hosts

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

unset BUILD_ZLIB BUILD_BZIP2

EOF

install_package XML-Parser-2.44.tar.gz << EOF

perl Makefile.PL

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package intltool-0.51.0.tar.gz << EOF

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

EOF

install_package autoconf-2.69.tar.xz << EOF

sed '361 s/{/\\{/' -i bin/autoscan.in

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package automake-1.16.1.tar.xz << EOF

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package xz-5.2.4.tar.xz << EOF

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/\$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

EOF

install_package kmod-26.tar.xz << EOF

./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/\$target
done

ln -sfv kmod /bin/lsmod

EOF

install_package gettext-0.19.8.1.tar.xz << EOF

sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

chmod -v 0755 /usr/lib/preloadable_libintl.so

EOF

install_package elfutils-0.176.tar.bz2 << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS -C libelf install

install -vm644 config/libelf.pc /usr/lib/pkgconfig

EOF

install_package libffi-3.2.1.tar.gz << EOF

sed -e '/^includesdir/ s/\$(libdir).*$/\$(includedir)/' \
    -i include/Makefile.in

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I\${includedir}/Cflags:/' \
    -i libffi.pc.in

# I hope that this is correct... (blame the docs if it's not lol)

# Select optimization
# export EXTRA_CONFIG_FLAGS="--with-gcc-arch=$LFS_ARCH" # Generic
export EXTRA_CONFIG_FLAGS="--with-gcc-arch=native" # Optimize for current hardware

# export CFLAGS="-march=$LFS_ARCH"
# export CXXFLAGS="-march=$LFS_ARCH"

echo "EXTRA_CONFIG_FLAGS:  Install with '\$EXTRA_CONFIG_FLAGS' flags"
echo "CC:  Install with '\$CFLAGS' flags"
echo "CXX: Install with '\$CXXFLAGS' flags"

./configure --prefix=/usr --disable-static \$EXTRA_CONFIG_FLAGS

make -j$BUILD_JOBS $MAKE_FLAGS

# make -j$BUILD_JOBS $MAKE_FLAGS check

make -j$BUILD_JOBS $MAKE_FLAGS install

unset EXTRA_CONFIG_FLAGS CFLAGS CXXFLAGS

EOF

install_package openssl-1.1.1a.tar.gz << EOF

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make -j$BUILD_JOBS $MAKE_FLAGS

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make -j$BUILD_JOBS $MAKE_FLAGS MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1a
cp -vfr doc/* /usr/share/doc/openssl-1.1.1a

EOF

install_package Python-3.7.2.tar.xz << EOF

./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so

install -v -dm755 /usr/share/doc/python-3.7.2/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.2/html \
    -xvf $SRC_DIR/python-3.7.2-docs-html.tar.bz2

EOF

install_package ninja-1.9.0.tar.gz << EOF

# Enable the use of "export NINJAJOBS=4"

sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

EOF

install_package meson-0.49.2.tar.gz << EOF

python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /

EOF

install_package coreutils-8.30.tar.xz << EOF

patch -Np1 -i $SRC_DIR/coreutils-8.30-i18n-1.patch

sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

FORCE_UNSAFE_CONFIGURE=1 make -j$BUILD_JOBS $MAKE_FLAGS

make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,nice,sleep,touch} /bin

EOF

install_package check-0.12.0.tar.gz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

sed -i '1 s/tools/usr/' /usr/bin/checkmk

EOF

install_package diffutils-3.7.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package gawk-4.2.1.tar.xz << EOF

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mkdir -v /usr/share/doc/gawk-4.2.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.2.1

EOF

install_package findutils-4.6.0.tar.gz << EOF

sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/usr --localstatedir=/var/lib/locate

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

EOF

install_package groff-1.22.4.tar.gz << EOF

PAGE=A4 ./configure --prefix=/usr

make -j1

make install

EOF

install_package dosfstools-4.1.tar.xz << EOF

./configure --prefix=/               \
            --enable-compat-symlinks \
            --mandir=/usr/share/man  \
            --docdir=/usr/share/doc/dosfstools-4.1

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package efivar-37.tar.bz2 << EOF

patch -Np1 -i $SRC_DIR/efivar-37-gcc_9-1.patch

make -j$BUILD_JOBS $MAKE_FLAGS LIBDIR=/usr/lib BINDIR=/bin CFLAGS="-O2 -Wno-stringop-truncation"
make -j$BUILD_JOBS $MAKE_FLAGS LIBDIR=/usr/lib BINDIR=/bin install

mv -v /usr/lib/lib{efivar,efiboot}.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libefivar.so) /usr/lib/libefivar.so
ln -sfv ../../lib/\$(readlink /usr/lib/libefiboot.so) /usr/lib/libefiboot.so

EOF

install_package popt-1.18.tar.gz << EOF

./configure --prefix=/usr --disable-static && \
make -j$BUILD_JOBS $MAKE_FLAGS

make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libpopt.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libpopt.so) /usr/lib/libpopt.so

EOF

install_package efibootmgr-17.tar.gz << EOF

sed -e '/extern int efi_set_verbose/d' -i src/efibootmgr.c

make -j$BUILD_JOBS $MAKE_FLAGS sbindir=/sbin EFIDIR=LFS EFI_LOADER=grubx64.efi
make -j$BUILD_JOBS $MAKE_FLAGS sbindir=/sbin EFIDIR=LFS EFI_LOADER=grubx64.efi install

EOF

install_package grub-2.02.tar.xz << EOF

# Patch grub EFI bug not mentioned in the LFS book.
# https://wiki.linuxfromscratch.org/lfs/ticket/4354

# sed -i '/R_X86_64_PC32:/a case R_X86_64_PLT32:' util/grub-mkimagexx.c
# sed -i '/R_X86_64_PC32,/a R_X86_64_PLT32,'      util/grub-module-verifier.c

./configure --prefix=/usr \
            --sbindir=/sbin \
            --sysconfdir=/etc \
            --disable-efiemu \
            --target=x86_64 \
            --with-platform=efi \
            --disable-werror

# --enable-grub-mkfont \

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

EOF

install_package less-530.tar.gz << EOF

./configure --prefix=/usr --sysconfdir=/etc

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package gzip-1.10.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/bin/gzip /bin

EOF

install_package iproute2-4.20.0.tar.xz << EOF

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

sed -i 's/.m_ipt.o//' tc/Makefile

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS DOCDIR=/usr/share/doc/iproute2-4.20.0 install

EOF

install_package kbd-2.0.4.tar.xz << EOF

patch -Np1 -i $SRC_DIR/kbd-2.0.4-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mkdir -v /usr/share/doc/kbd-2.0.4
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4

EOF

install_package libpipeline-1.5.1.tar.gz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package make-4.2.1.tar.bz2 << EOF

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package patch-2.7.6.tar.xz << EOF

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package man-db-2.8.5.tar.xz << EOF

./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.5 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package tar-1.31.tar.xz << EOF

sed -i 's/abort.*/FALLTHROUGH;/' src/extract.c

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install
make -C doc install-html docdir=/usr/share/doc/tar-1.31

EOF

install_package texinfo-6.5.tar.xz << EOF

sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm

./configure --prefix=/usr --disable-static

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

make -j$BUILD_JOBS $MAKE_FLAGS TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
rm -v dir
for f in *
  do install-info \$f dir 2>/dev/null
done
popd

EOF

install_package vim-8.1.tar.bz2 << EOF

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 \$(dirname \$L)/vi.1
done

ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1

export VIMRUNTIME=/usr/share/vim/vim81/

cat > /etc/vimrc << "LFS_EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source \$VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
" set spelllang=en,th
" set spell
syntax on

if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
LFS_EOF

unset VIMRUNTIME

EOF

install_package systemd-240.tar.gz << EOF

patch -Np1 -i $SRC_DIR/systemd-240-security_fixes-2.patch

ln -sf /tools/bin/true /usr/bin/xsltproc

for file in /tools/lib/lib{blkid,mount,uuid}*; do
    ln -sf \$file /usr/lib/
done

tar -xf $SRC_DIR/systemd-man-pages-240.tar.xz

sed '177,$ d' -i src/resolve/meson.build

sed -i 's/GROUP="render", //' rules/50-udev-default.rules.in

mkdir -p build
cd       build

PKG_CONFIG_PATH="/usr/lib/pkgconfig:/tools/lib/pkgconfig" \
LANG=en_US.UTF-8                   \
meson --prefix=/usr                \
      --sysconfdir=/etc            \
      --localstatedir=/var         \
      -Dblkid=true                 \
      -Dbuildtype=release          \
      -Ddefault-dnssec=no          \
      -Dfirstboot=false            \
      -Dinstall-tests=false        \
      -Dkill-path=/bin/kill        \
      -Dkmod-path=/bin/kmod        \
      -Dldconfig=false             \
      -Dmount-path=/bin/mount      \
      -Drootprefix=                \
      -Drootlibdir=/lib            \
      -Dsplit-usr=true             \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false             \
      -Dumount-path=/bin/umount    \
      -Db_lto=false                \
      ..

NINJAJOBS=$BUILD_JOBS LANG=en_US.UTF-8 ninja
NINJAJOBS=$BUILD_JOBS LANG=en_US.UTF-8 ninja install

rm -rfv /usr/lib/rpm
rm -f /usr/bin/xsltproc

systemd-machine-id-setup

cat > /lib/systemd/systemd-user-sessions << "LFS_EOF"
#!/bin/bash
rm -f /run/nologin
LFS_EOF

chmod 755 /lib/systemd/systemd-user-sessions

EOF

install_package dbus-1.12.12.tar.gz << EOF

./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.12.12 \
            --with-console-auth-dir=/run/console \
            --enable-systemd

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so

ln -sfv /etc/machine-id /var/lib/dbus

EOF

install_package procps-ng-3.3.15.tar.xz << EOF

./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/\$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

EOF

install_package util-linux-2.33.1.tar.xz << EOF

mkdir -pv /var/lib/hwclock

rm -vf /usr/include/{blkid,libmount,uuid}

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.33.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package e2fsprogs-1.44.5.tar.gz << EOF

mkdir -v build
cd build

../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install
make -j$BUILD_JOBS $MAKE_FLAGS install-libs

chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

# Documentations for file system project :)
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

EOF

install_package Linux-PAM-1.3.0.tar.bz2 << EOF

tar -xf /sources/Linux-PAM-1.2.0-docs.tar.bz2 --strip-components=1

./configure --prefix=/usr                    \
            --sysconfdir=/etc                \
            --libdir=/usr/lib                \
            --disable-regenerate-docu        \
            --enable-securedir=/lib/security \
            --docdir=/usr/share/doc/Linux-PAM-1.3.0 &&

make -j$BUILD_JOBS $MAKE_FLAGS

if [ ! -d /etc/pam.d ]; then

install -v -m755 -d /etc/pam.d &&

cat > /etc/pam.d/other << "LFS_EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
LFS_EOF

rm -fv /etc/pam.d/*

make install &&
chmod -v 4755 /sbin/unix_chkpwd &&

for file in pam pam_misc pamc
do
  mv -v /usr/lib/lib\${file}.so.* /lib &&
  ln -sfv ../../lib/\$(readlink /usr/lib/lib\${file}.so) /usr/lib/lib\${file}.so
done

fi

install -vdm755 /etc/pam.d &&
cat > /etc/pam.d/system-account << "LFS_EOF" &&
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
LFS_EOF

cat > /etc/pam.d/system-auth << "LFS_EOF" &&
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
LFS_EOF

cat > /etc/pam.d/system-session << "LFS_EOF"
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
LFS_EOF

if [ -d /lib/cracklib ]; then

cat > /etc/pam.d/system-password << "LFS_EOF"
# Begin /etc/pam.d/system-password

# check new passwords for strength (man pam_cracklib)
password  required    pam_cracklib.so    authtok_type=UNIX retry=1 difok=5 \
                                         minlen=9 dcredit=1 ucredit=1 \
                                         lcredit=1 ocredit=1 minclass=0 \
                                         maxrepeat=0 maxsequence=0 \
                                         maxclassrepeat=0 \
                                         dictpath=/lib/cracklib/pw_dict
# use sha512 hash for encryption, use shadow, and use the
# authentication token (chosen password) set by pam_cracklib
# above (or any previous modules)
password  required    pam_unix.so        sha512 shadow use_authtok

# End /etc/pam.d/system-password
LFS_EOF

else

cat > /etc/pam.d/system-password << "LFS_EOF"
# Begin /etc/pam.d/system-password

# use sha512 hash for encryption, use shadow, and try to use any previously
# defined authentication token (chosen password) set by any prior module
password  required    pam_unix.so       sha512 shadow try_first_pass

# End /etc/pam.d/system-password
LFS_EOF

fi

cat > /etc/pam.d/other << "LFS_EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
LFS_EOF

EOF

install_package shadow-4.6.tar.xz 2 << EOF

sed -i 's/groups$(EXEEXT) //' src/Makefile.in &&

find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; &&
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; &&
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; &&

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs &&

sed -i 's/1000/999/' etc/useradd                           &&

./configure --sysconfdir=/etc --with-group-name-max-length=32 &&
make -j$BUILD_JOBS $MAKE_FLAGS

make -j$BUILD_JOBS $MAKE_FLAGS install &&
mv -v /usr/bin/passwd /bin

install -v -m644 /etc/login.defs /etc/login.defs.orig &&
for FUNCTION in FAIL_DELAY               \
                FAILLOG_ENAB             \
                LASTLOG_ENAB             \
                MAIL_CHECK_ENAB          \
                OBSCURE_CHECKS_ENAB      \
                PORTTIME_CHECKS_ENAB     \
                QUOTAS_ENAB              \
                CONSOLE MOTD_FILE        \
                FTMP_FILE NOLOGINS_FILE  \
                ENV_HZ PASS_MIN_LEN      \
                SU_WHEEL_ONLY            \
                CRACKLIB_DICTPATH        \
                PASS_CHANGE_TRIES        \
                PASS_ALWAYS_WARN         \
                CHFN_AUTH ENCRYPT_METHOD \
                ENVIRON_FILE
do
    sed -i "s/^\${FUNCTION}/# &/" /etc/login.defs
done

cat > /etc/pam.d/login << "LFS_EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth      optional    pam_faildelay.so  delay=3000000

# Check to make sure that the user is allowed to login
auth      requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function. See man 5 securetty.
#auth      required    pam_securetty.so

# Additional group memberships - disabled by default
#auth      optional    pam_group.so

# include system auth settings
auth      include     system-auth

# check access for the user
account   required    pam_access.so

# include system account settings
account   include     system-account

# Set default environment variables for the user
session   required    pam_env.so

# Set resource limits for the user
session   required    pam_limits.so

# Display date of last login - Disabled by default
#session   optional    pam_lastlog.so

# Display the message of the day - Disabled by default
#session   optional    pam_motd.so

# Check user's mail - Disabled by default
#session   optional    pam_mail.so      standard quiet

# include system session and password settings
session   include     system-session
password  include     system-password

# End /etc/pam.d/login
LFS_EOF

cat > /etc/pam.d/passwd << "LFS_EOF"
# Begin /etc/pam.d/passwd

password  include     system-password

# End /etc/pam.d/passwd
LFS_EOF

cat > /etc/pam.d/su << "LFS_EOF"
# Begin /etc/pam.d/su

# always allow root
auth      sufficient  pam_rootok.so

# Allow users in the wheel group to execute su without a password
# disabled by default
#auth      sufficient  pam_wheel.so trust use_uid

# include system auth settings
auth      include     system-auth

# limit su to users in the wheel group
auth      required    pam_wheel.so use_uid

# include system account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session settings
session   include     system-session

# End /etc/pam.d/su
LFS_EOF

cat > /etc/pam.d/chage << "LFS_EOF"
# Begin /etc/pam.d/chage

# always allow root
auth      sufficient  pam_rootok.so

# include system auth, account, and session settings
auth      include     system-auth
account   include     system-account
session   include     system-session

# Always permit for authentication updates
password  required    pam_permit.so

# End /etc/pam.d/chage
LFS_EOF

for PROGRAM in chfn chgpasswd chpasswd chsh groupadd groupdel \
               groupmems groupmod newusers useradd userdel usermod
do
    install -v -m644 /etc/pam.d/chage /etc/pam.d/\${PROGRAM}
    sed -i "s/chage/\$PROGRAM/" /etc/pam.d/\${PROGRAM}
done

rm -f /run/nologin

[ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}

[ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}

EOF

## MAIN INSTALL DONE! ##

install_package lynx2.8.9rel.1.tar.bz2 << EOF

./configure --prefix=/usr          \
            --sysconfdir=/etc/lynx \
            --datadir=/usr/share/doc/lynx-2.8.9rel.1 \
            --with-zlib            \
            --with-bzlib           \
            --with-ssl             \
            --with-screen=ncursesw \
            --enable-locale-charset

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install-full

chgrp -v -R root /usr/share/doc/lynx-2.8.9rel.1/lynx_doc

sed -e '/#LOCALE/     a LOCALE_CHARSET:TRUE'     \
    -i /etc/lynx/lynx.cfg

sed -e '/#DEFAULT_ED/ a DEFAULT_EDITOR:vi'       \
    -i /etc/lynx/lynx.cfg

sed -e '/#PERSIST/    a PERSISTENT_COOKIES:TRUE' \
    -i /etc/lynx/lynx.cfg

EOF

install_package openssh-7.9p1.tar.gz << EOF

install  -v -m700 -d /var/lib/sshd &&
chown    -v root:sys /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd

patch -Np1 -i $SRC_DIR/openssh-7.9p1-security_fix-1.patch &&
./configure --prefix=/usr                     \
            --sysconfdir=/etc/ssh             \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd &&

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-7.9p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-7.9p1

# Temporary permitting root login (needs to be changed after installation)
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd &&
chmod 644 /etc/pam.d/sshd &&
echo "UsePAM yes" >> /etc/ssh/sshd_config

EOF

install_package wget-1.20.1.tar.gz << EOF

./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

install_package blfs-systemd-units-20180105.tar.bz2 << EOF

make install-sshd

EOF

# Clean up

rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a

find /usr/lib /usr/libexec -name \*.la -delete
