#!/bin/sh

new_control=$1

if [ -z $new_control ];then
	echo "usage: ./change_control.sh net-control"
	exit
fi

old_control=`grep rabbit_host /etc/nova/nova.conf |grep -v ^# | awk '{print $3}'`
echo "原控制节点: $old_control"
echo "新控制节点: $new_control"

h=`hostname`
if [ $h == $old_control ];then
	echo "请不要在控制节点上执行"
	exit
fi

config_file=(
        "/etc/nova/nova.conf"
        "/etc/neutron/neutron.conf"
        )

t=`date +%F_%H%M%S`
for f in ${config_file[@]}; do
        cp $f $f.$t
	sed -i "s/$old_control/$new_control/g" $f
done

service openstack-nova-compute restart
service neutron-openvswitch-agent restart
