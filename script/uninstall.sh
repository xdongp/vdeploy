#!/usr/bin/env bash
source ./config.sh

UNINSTALL=$ROOT_DIR/script/uninstall_openstack.sh

echo "删除控制节点"
ssh $CONTROL $UNINSTALL
echo "删除计算节点"
num=${#COMPUTE[@]}
spice=`echo 50/$num|bc`
for ((i=0;i<num;i++))
{
   host=${COMPUTE[i]};
   echo "删除 $host ..."
   ssh $host $UNINSTALL
}
echo "finish uninstall"
