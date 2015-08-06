#!/bin/sh

if [ $# -ne 3 ]; then
        echo "net_create 172.16.1.0  109 miui"
        exit
fi

NET=$1
VLANID=$2
BUSS=$3

NETNAME=${BUSS}_${VLANID}
SUBNAME=net_$NET

echo $NETNAME
tenant=$(keystone tenant-list|awk '/admin/ {print $2}')
gw=`echo $NET|sed -e 's/[0-9]*$/254/'`

neutron net-create --tenant-id $tenant $NETNAME \
                   --provider:network_type vlan \
                   --provider:physical_network physnet1 \
                   --provider:segmentation_id $VLANID
#neutron subnet-create --tenant-id $tenant --name $SUBNAME  $NETNAME  $NET/24   --gateway $gw --allocation-pool start=10.108.97.210,end=10.108.97.215
neutron subnet-create --tenant-id $tenant --name $SUBNAME  $NETNAME  $NET/24   --gateway $gw
