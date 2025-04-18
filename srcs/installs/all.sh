
pushd $(dirname "$0")
  bash $PWD/gcc.sh
  bash $PWD/sysutils.sh
  bash $PWD/init_target.sh
  bash $PWD/chroot.sh
  bash $PWD/configure_target.sh
popd
