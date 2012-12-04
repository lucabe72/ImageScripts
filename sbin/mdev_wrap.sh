#!/bin/sh

echo >>/tmp/mdev.trace
date >>/tmp/mdev.trace
echo "Params: $*" >>/tmp/mdev.trace
env | sort >>/tmp/mdev.trace

[ "$ACTION" = add ] && [ "$MODALIAS" != "" ] && /sbin/modprobe $MODALIAS
[ "$ACTION" = remove ] && [ "$MODALIAS" != "" ] && /sbin/modprobe -r $MODALIAS
/sbin/mdev $@

