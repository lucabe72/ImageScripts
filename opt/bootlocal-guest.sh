IFACES="eth0-192.168.1.3,eth0:0-192.168.2.3"
CMDLINE=$(cat /proc/cmdline)

for cmd in $CMDLINE
 do
   case $cmd in
     ifaces*) IFACES=${cmd#*=} ;;
     gw*) GATEWAY=${cmd#*=} ;;
     noroute) NOROUTE=YesPlease ;;
   esac
 done

echo IFACES: $IFACES

IFS=,
for I in $IFACES
 do
  NAME=$(echo $I | cut -d '-' -f 1)
  IPM=$(echo $I | cut -d '-' -f 2)
  IP=$(echo $IPM | cut -d 'm' -f 1)
  MASK=$(echo $IPM | cut -d 'm' -f 2)
  /sbin/ifconfig $NAME $IP
  if [ "x$MASK" != "x" ]
   then
    /sbin/ifconfig $NAME netmask $MASK
  fi
  /sbin/ifconfig $NAME txqueuelen 20000
 done

if [ "x$GATEWAY" != "x" ]
 then
  route add default gw $GATEWAY
fi

if [ x$NOROUTE = x ]
 then
  echo 1 > /proc/sys/net/ipv4/ip_forward
  cd /home/vrouter
  Public-Quagga/lib64/ld-linux-x86-64.so.2 --library-path Public-Quagga/lib:Public-Quagga/lib64 Public-Quagga/sbin/zebra -u root -g root -f zebra.conf -d
  Public-Quagga/lib64/ld-linux-x86-64.so.2 --library-path Public-Quagga/lib:Public-Quagga/lib64 Public-Quagga/sbin/ospfd -u root -g root -f ospfd.conf -d
fi

