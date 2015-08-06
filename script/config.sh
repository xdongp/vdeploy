
#!/bin/sh
export CONTROL='10.0.0.1'
export COMPUTE='10.0.0.2 10.0.0.3 10.0.0.4 10.0.0.1'
export NETMODEL=GRE
export NETDEV=eth0
export TRUNKDEV=eth1
export EXNET=eth0
export STORE=LVM
export PASS='verystack0okm'
export MYIP=`ifconfig $NETDEV|grep "inet addr:"|awk '{print $2}'|awk -F':' '{print $2}'`
export MYMAC=`ifconfig $NETDEV|grep HW|awk  '{print $5}'`
