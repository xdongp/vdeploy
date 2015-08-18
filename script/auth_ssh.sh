#!/usr/bin/env bash
#作用： 建立信任关系

HOST=$1
PASS=$2
if [ -z $HOST ] || [ -z $PASS ]; then
    echo "输入参数错误"
    exit 1
fi

source ./install_openstack_lib.sh
keygen
copy_ssh $HOST $PASS
