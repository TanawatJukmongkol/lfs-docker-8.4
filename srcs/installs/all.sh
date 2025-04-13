
pushd $(dirname "$0")
  bash $PWD/gcc.sh
  bash $PWD/sysutils.sh
popd
