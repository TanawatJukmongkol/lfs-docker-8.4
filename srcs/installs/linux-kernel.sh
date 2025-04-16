
HOSTNAME=tjukmong
KERNEL_VER="4.20.12"
TAR_DIR=/sources
SRC_DIR=/usr/src/kernel-$KERNEL_VER

BUILD_JOBS=$(( $( nproc ) * 3 / 2 ))
MAKE_FLAGS="-l $( nproc )"

if [ ! -d $SRC_DIR ]; then
    mkdir -p $SRC_DIR
    tar -xvf  $TAR_DIR/linux-"$KERNEL_VER".tar.xz -C $SRC_DIR --strip-components=1
    make -j$BUILD_JOBS $MAKE_FLAGS -C $SRC_DIR mrproper
    make -j$BUILD_JOBS $MAKE_FLAGS -C $SRC_DIR defconfig
fi

pushd $SRC_DIR

make -j$BUILD_JOBS $MAKE_FLAGS menuconfig
make -j$BUILD_JOBS $MAKE_FLAGS
make -j$BUILD_JOBS $MAKE_FLAGS modules_install

cp -iv arch/x86/boot/bzImage /boot/vmlinuz-"$KERNEL_VER"-"$HOSTNAME"
cp -iv System.map /boot/System.map-"$KERNEL_VER"
cp -iv .config /boot/config-"$KERNEL_VER"

if [ ! -d /usr/share/doc/linux-$KERNEL_VER ]; then
  install -d /usr/share/doc/linux-$KERNEL_VER
  cp -r Documentation/* /usr/share/doc/linux-$KERNEL_VER
fi

popd

install -v -m755 -d /etc/modprobe.d

cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

