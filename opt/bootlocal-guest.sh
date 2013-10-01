IFACES="eth0-192.168.1.3,eth0:0-192.168.2.3"
CMDLINE=$(cat /proc/cmdline)

for cmd in $CMDLINE
 do
   case $cmd in
     ifaces*) IFACES=${cmd#*=} ;;
     noroute) NOROUTE=YesPlease ;;
   esac
 done

echo IFACES: $IFACES

IFS=,
for I in $IFACES
 do
  NAME=$(echo $I | cut -d '-' -f 1)
  IP=$(echo $I | cut -d '-' -f 2)
  /sbin/ifconfig $NAME $IP
  /sbin/ifconfig $NAME txqueuelen 20000
 done

if [ x$NOROUTE = x ]
 then
  echo 1 > /proc/sys/net/ipv4/ip_forward
 fi
