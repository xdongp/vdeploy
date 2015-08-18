#!/usr/bin/env bash

source ./config.sh
source ./install_openstack_lib.sh

function install_control(){
    host=$1
    curl "http://127.0.0.1:8080/host/progress?progress=10&ip=$host"
    bash control_init.sh
    curl "http://127.0.0.1:8080/host/progress?progress=30&ip=$host"
    bash control_install.sh
    curl "http://127.0.0.1:8080/host/progress?progress=100&ip=$host"

}

function install_compute(){
    host=$1
    curl "http://127.0.0.1:8080/host/progress?progress=10&ip=$host"
    ssh $host mkdir -p $ROOT_DIR/script
    scp compute_init.sh $host:$ROOT_DIR/script
    scp compute_install.sh $host:$ROOT_DIR/script
    ssh $host chmod +x $ROOT_DIR/script/*.sh
    curl "http://127.0.0.1:8080/host/progress?progress=30&ip=$host"
    bash compute_init.sh
    curl "http://127.0.0.1:8080/host/progress?progress=50&ip=$host"
    bash compute_install.sh
    curl "http://127.0.0.1:8080/host/progress?progress=100&ip=$host"
}


logit "start install ..."
curl  $SERVICE_URL/progress?progress=10

echo "初始化环境"
execute_cmd "yum -y install expect"
curl  $SERVICE_URL/progress?progress=20

echo "建立信任过关系"
#if [ -f auth_ssh.sh ]; then
#    bash auth_ssh.sh
#else
#    exit 1
#fi
curl  $SERVICE_URL/progress?progress=30

echo "安装控制节点"
#install_control $CONTROL
curl  $SERVICE_URL/progress?progress=40
echo "安装计算节点"
num=${#COMPUTE[@]}
spice=`echo 50/$num|bc`
for ((i=0;i<num;i++))
{
   host=${COMPUTE[i]};
   echo "安装 $host ..."
   install_compute $host;
   progress=`echo 40+$spice+$spice*$i |bc`
   curl $SERVICE_URL/progress?progress=$progress
}
sleep 5
curl $SERVICE_URL/progress?progress=100
echo "finish install"
