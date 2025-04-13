
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

patch -Np1 -i ../glibc-2.29-fhs-1.patch

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
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
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
# localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
# localedef -i de_DE -f ISO-8859-1 de_DE
# localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
# localedef -i de_DE -f UTF-8 de_DE.UTF-8
# localedef -i el_GR -f ISO-8859-7 el_GR
# localedef -i en_GB -f UTF-8 en_GB.UTF-8
# localedef -i en_HK -f ISO-8859-1 en_HK
# localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
# localedef -i es_MX -f ISO-8859-1 es_MX
# localedef -i fa_IR -f UTF-8 fa_IR
# localedef -i fr_FR -f ISO-8859-1 fr_FR
# localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
# localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
# localedef -i it_IT -f ISO-8859-1 it_IT
# localedef -i it_IT -f UTF-8 it_IT.UTF-8
# localedef -i ja_JP -f EUC-JP ja_JP
# localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
# localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
# localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
# localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
# localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
# localedef -i zh_CN -f GB18030 zh_CN.GB18030
# localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

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

# If you want, install cracklib here

wget_list << EOF
https://ftp2.osuosl.org/pub/blfs/conglomeration/Linux-PAM/Linux-PAM-1.3.0.tar.bz2
https://ftp2.osuosl.org/pub/blfs/conglomeration/Linux-PAM/Linux-PAM-1.2.0-docs.tar.bz2
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

install_package shadow-4.6.tar.xz << EOF

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

passwd root << PASSWD
lfs
lfs
lfs

PASSWD

EOF

install_package gcc-8.2.0.tar.xz << EOF

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

rm -f /usr/lib/gcc

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

# su nobody -s /bin/bash -c "PATH=$PATH make -k check"

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

