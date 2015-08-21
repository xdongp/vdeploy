#!/usr/bin/env bash

source ./config.sh

function install_control(){
    host=$1
    curl "http://127.0.0.1:22222/api/host/progress?progress=10&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=20&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=30&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=40&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=50&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=60&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=70&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=80&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=90&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=100&ip=$host"
}


function install_compute(){
    host=$1
    curl "http://127.0.0.1:22222/api/host/progress?progress=10&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=20&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=30&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=40&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=50&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=60&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=70&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=80&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=90&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=100&ip=$host"
}


echo "start install ..." >> install.log
curl http://127.0.0.1:22222/api/progress?progress=10
echo "初始化环境"
sleep 5
curl http://127.0.0.1:22222/api/progress?progress=20
echo "简历信任过关系"
sleep 5
curl http://127.0.0.1:22222/api/progress?progress=30
echo "安装控制节点"
install_control $CONTROL
curl http://127.0.0.1:22222/api/progress?progress=40
echo "安装计算节点"
num=${#COMPUTE[@]}
spice=`echo 50/$num|bc`
for ((i=0;i<num;i++))
{
   host=${COMPUTE[i]};
   echo "安装 $host ..."
   install_compute $host;
   progress=`echo 40+$spice+$spice*$i |bc`
   curl http://127.0.0.1:22222/api/progress?progress=$progress
}
sleep 5
curl http://127.0.0.1:22222/api/progress?progress=100
echo "finish install" >> install.log


