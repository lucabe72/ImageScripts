set -e

. $(dirname $0)/utils.sh
. $(dirname $0)/opts_parse.sh

my_cp() {
  FILE=$(find /lib -name $1)
  sudo cp $FILE $2
}

update_libs()
{
LIBS="libc.so.6 libm.so.6 libpthread.so.0 libanl.so.1 libnsl.so.1 libresolv.so.2 libnss_compat.so.2 librt.so.1 libcrypt.so.1 libnss_dns.so.2 libutil.so.1 libdl.so.2 libnss_files.so.2"

LD="ld-linux.so.2"

  for l in $LIBS
   do
    my_cp $l $1
   done

  sudo cp /lib/$LD $1
}

update_initramfs_libs()
{
  extract_initramfs $1  $2/tmproot
  update_libs $2/tmproot/lib
  mk_initramfs  $2/tmproot $3
}

mkdir -p /tmp/NewCore
update_initramfs_libs $1 /tmp/NewCore $2
