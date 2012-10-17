mount_partition()
{
  SIZE=$(echo $(/sbin/sfdisk -l -u S $1 | grep $2) | cut -d ' ' -f 4)
  START=$(echo $(/sbin/sfdisk -l -u S $1 | grep $2) | cut -d ' ' -f 2)
  echo Size: $SIZE
  echo Start: $START
  START=$((START*512))
  SIZE=$((SIZE*512))

  sudo /sbin/losetup -o $START /dev/loop0 $1
  sudo mount /dev/loop0 $3
}

format_partition() {
  echo Formatting partition $2 on $1
  echo Getting partition information...
  SIZE=$(echo $(/sbin/sfdisk -l -u S $1 | grep img$2) | cut -d ' ' -f 4)
  START=$(echo $(/sbin/sfdisk -l -u S $1 | grep img$2) | cut -d ' ' -f 2)
  echo Size: $SIZE
  echo Start: $START
  START=$((START*512))
  SIZE=$((SIZE*512))

  echo Creating a FS on the partition...
  sudo /sbin/losetup --offset $START --sizelimit $SIZE /dev/loop0 $1
  sudo /sbin/mkfs.ext3 /dev/loop0
  sudo /sbin/losetup -d /dev/loop0
}

get_cpus() {
  echo $(grep processor /proc/cpuinfo | tail -n 1) | cut -d ' ' -f 3
}

get_exec_libs() {
  LIBS=$(ldd $1 | cut -f 2 | cut -d ' ' -f 3)
  for L in $LIBS
   do
    cp $L $2
   done
}

extract_initramfs() {
  echo Extract $1 $2
  HERE=$PWD
  sudo rm -rf $2
  mkdir $2
  cd $2
  zcat $1 | sudo cpio -i
  cd $HERE
}

mk_initramfs() {
  echo MkInitRAMFs $1 $2
  HERE=$PWD
  cd $1
  sudo find . | sudo cpio -o -H newc | gzip > $2
  cd $HERE
}


