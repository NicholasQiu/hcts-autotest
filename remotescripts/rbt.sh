#!/usr/bin/bash
arch=`uname -p`;
test $arch == "sparc" && rbt_opt="net:dhcp - install" || rbt_opt="-p"
sync;
sync;
echo "nohup /usr/sbin/reboot $rbt_opt" | at now + 1 minute
