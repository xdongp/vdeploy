#!/usr/bin/env bash

source ./config.sh
source ./utils.sh


function install_control(){
    host=$1
    set_host_progress $host 10
    bash install_control.sh
    set_host_progress $host 100
}

function install_compute(){
    host=$1
    set_host_progress $host 10
    ssh $host mkdir -p $ROOT_DIR/script
    scp *.sh $host:$ROOT_DIR/script
    ssh $host chmod +x $ROOT_DIR/script/*.sh
    set_host_progress $host 30
    ssh $host "cd $ROOT_DIR/script && sh install_compute.sh"
    set_host_progress $host 100
}


logit "start install ..."
set_main_progress 10

echo "初始化环境"
execute_cmd "yum -y install expect"
set_main_progress 20

echo "建立信任过关系"
#这一步初始化已经完成了,略过
set_main_progress 30

echo "安装控制节点"
install_control $CONTROL
set_main_progress 40
echo "安装计算节点"
num=${#COMPUTE[@]}
spice=`echo 50/$num|bc`
for ((i=0;i<num;i++))
{
   host=${COMPUTE[i]};
   echo "安装 $host ..."
   install_compute $host;
   progress=`echo 40+$spice+$spice*$i |bc`
   set_main_progress $progress
}
sleep 5
set_main_progress 100
echo "finish install"
