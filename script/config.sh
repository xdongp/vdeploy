
#!/bin/sh
export SERVICE_URL=http://127.0.0.1:8080
export CONTROL='10.0.0.1'
export COMPUTE=(10.0.0.2 10.0.0.3)
export NETMODEL=VLAN
export NETDEV=eth0
export TRUNKDEV=eth1
export EXNET=eth0
export STORE=LVM
export PASS='verystack0okm'
export MYIP=`ifconfig $NETDEV|grep "inet addr:"|awk '{print $2}'|awk -F':' '{print $2}'`
export MYMAC=`ifconfig $NETDEV|grep HW|awk  '{print $5}'`
