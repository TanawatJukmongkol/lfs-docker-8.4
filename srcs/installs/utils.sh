
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

install_package () {
  tarball=$1
  install_version=$2
  pname=$install_version'_'$tarball

  pushd $SRC_DIR
  if [ -e $BUILD_DIR/$pname.installed ]; then
    echo $tarball was already installed. skip...
    return
  else
    echo "Installing $1..."
    if [ ! "$2" = "" ] && [ ! $2 = 1 ]; then
      prev_version=$(( $install_version - 1 ))'_'$1.installed
      if [ ! -e $BUILD_DIR/$prev_version ]; then
        echo $prev_version, not found! Terminated.
        exit 1
      fi
      echo "Upgrading $1 to #$install_version..."
      mv $BUILD_DIR/$prev_version $BUILD_DIR/$pname
      touch $BUILD_DIR/$prev_version
      pushd $BUILD_DIR/$pname
        (eval "$(cat /dev/stdin)" ; mv $BUILD_DIR/$pname $BUILD_DIR/$pname.installed) \
        || mv $BUILD_DIR/$pname $BUILD_DIR/$prev_version # revert back the name if failed
      popd
      return
    else
      mkdir -p $BUILD_DIR/$pname
      tar -xvf $tarball -C $BUILD_DIR/$pname --strip-components=1
    fi
  fi
  popd

  pushd $BUILD_DIR/$pname
    (eval "$(cat /dev/stdin)" ; mv $BUILD_DIR/$pname $BUILD_DIR/$pname.installed) \
    || (echo "Error installing $pname. Terminated."; exit 1)
  popd
}

sp="/-\|"
sc=0
spin() {
   printf "\b${sp:sc++:1}"
   ((sc==${#sp})) && sc=0
}

endspin() {
   printf "\r%s\n" "$@"
}

wget_script () {
  echo "Fetching $i..."
  wget $i -qc -P $SRC_DIR
  if [ "$?" -ne "0" ]; then
    echo "Failed to fetch from $i. Terminated."
    exit 127
  fi
  echo "$i Finish downloading!"
}

wget_list () {
  urls=""
  pids=""
  for i in $(cat /dev/stdin); do
    wget_script &
    pids="$! $pids"
    urls="$i $urls"
  done
  # Wait on pids (and exit on error)
  werr=0
  err=0
  err_pid=0
  for pid in $pids; do
    wait $pid || werr=$?
    ! [ $werr = 127 ] || break
    err=$werr
    err_pid=$pid
  done
  if [ "$err" -ne "0" ]; then
    exit $err
  fi
}
