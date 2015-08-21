#!/bin/sh
export ROOT_DIR=/opt/vdeploy
export SERVICE_URL=http://172.16.18.170:22222
export CONTROL='172.16.18.170'
export COMPUTE=(172.16.18.171)
export NETMODEL=VLAN
export NETDEV=eth0
export TRUNKDEV=eth1
export EXNET=eth0
export STORE=LVM
export PASS='verystack0okm'
export MYIP=`ifconfig $NETDEV|grep "inet addr:"|awk '{print $2}'|awk -F':' '{print $2}'`
export MYMAC=`ifconfig $NETDEV|grep HW|awk  '{print $5}'`
