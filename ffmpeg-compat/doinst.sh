
if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) ARCH=i486 ;;
    arm*) ARCH=arm ;;
       *) ARCH=$( uname -m ) ;;
  esac
fi

if [ "$ARCH" = "x86_64" ]; then
  LIBDIRSUFFIX="64"
else
  LIBDIRSUFFIX=""
fi

if ! grep -q  /etc/ld.so.conf ; then
  echo "/usr/lib${LIBDIRSUFFIX}/ffmpeg-compat" >> /etc/ld.so.conf
fi

if [ -x /sbin/ldconfig ]; then
  /sbin/ldconfig 2> /dev/null
fi
