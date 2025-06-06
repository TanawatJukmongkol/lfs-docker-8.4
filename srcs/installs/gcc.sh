#!/usr/bin/env bash

source utils.sh

BUILD_DIR=/persist/home/lfs/build/gcc/
SRC_DIR=/mnt/lfs/sources/

mkdir -p $BUILD_DIR

wget_list << EOF
http://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.xz
https://ftp.gnu.org/gnu/mpfr/mpfr-4.0.2.tar.xz
http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz
https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.xz
https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.20.12.tar.xz
http://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.xz
EOF

# Pass 1
# Binutils-2.32

install_package binutils-2.32.tar.xz 1 << EOF

mkdir -v build
cd       build

../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

make -j$BUILD_JOBS $MAKE_FLAGS

case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac

make -j$BUILD_JOBS $MAKE_FLAGS install

EOF


# GCC-8.2.0

install_package gcc-8.2.0.tar.xz 1 << EOF

tar -xf $SRC_DIR/mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf $SRC_DIR/gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf $SRC_DIR/mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv \$file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' \$file.orig > \$file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> \$file
  touch \$file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build
cd       build

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

# Linux-4.20.12

install_package linux-4.20.12.tar.xz << EOF

make mrproper

make INSTALL_HDR_PATH=dest \
     -j$BUILD_JOBS $MAKE_FLAGS \
     headers_install

cp -rv dest/include/* /tools/include

EOF

# Glibc-2.29

install_package glibc-2.29.tar.xz << EOF

mkdir -v build
cd       build

../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=\$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

# echo 'int main(){}' > dummy.c
# $LFS_TGT-gcc dummy.c
# readelf -l a.out | grep ': /tools'
# rm -v dummy.c a.out

EOF

# Libstdc++ from GCC-8.2.0

install_package gcc-8.2.0.tar.xz 2 << EOF

rm -rf   build
mkdir -v build
cd       build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

EOF

# Pass 2
# Binutils-2.32 - Pass 2

install_package binutils-2.32.tar.xz 2 << EOF

rm -rf   build

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib

cp -v ld/ld-new /tools/bin

EOF

# GCC-8.2.0 - Pass 2 

install_package gcc-8.2.0.tar.xz 3 << EOF

rm -rf build

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  \$(dirname \$($LFS_TGT-gcc -print-libgcc-file-name))/include-fixed/limits.h

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv \$file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' \$file.orig > \$file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> \$file
  touch \$file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

tar -xf $SRC_DIR/mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf $SRC_DIR/gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf $SRC_DIR/mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp

make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS install

ln -sv gcc /tools/bin/cc

EOF
