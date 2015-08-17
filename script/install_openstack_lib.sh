#!/bin/bash
export LOG_FILE="./install.log"

function logit() {
    echo "`date` - ${*}" >> ${LOG_FILE}
}

function handle_network()
{
	cd /etc/udev/rules.d && mv 70-persistent-net.rules /root/ 
	cd /etc/sysconfig/network-scripts/
	find ifcfg-eth0 ifcfg-eth1 ifcfg-eth2 ifcfg-eth3
	if [[ $? != 0 ]]
	then
		echo "缺少网卡文件"
		exit 1
	else 
		#mv ifcfg-eth0  ifcfg-eth2.bak
		#mv ifcfg-eth1  ifcfg-eth3.bak
		#mv ifcfg-eth2  ifcfg-eth0
		#mv ifcfg-eth3  ifcfg-eth1
		#mv ifcfg-eth2.bak  ifcfg-eth2
		#mv ifcfg-eth3.bak  ifcfg-eth3
		#sed  -i "s/eth2/eth0/g" ifcfg-eth0
		#sed  -i "s/eth3/eth1/g" ifcfg-eth1
		#sed  -i "s/eth0/eth2/g" ifcfg-eth2
		#sed  -i "s/eth1/eth3/g" ifcfg-eth3
		mv ifcfg-eth0 ifcfg-em1 && sed  -i "s/eth0/em1/g" ifcfg-em1
		mv ifcfg-eth1 ifcfg-em2 && sed  -i "s/eth1/em2/g" ifcfg-em2
		mv ifcfg-eth2 ifcfg-em3 && sed  -i "s/eth2/em3/g" ifcfg-em3
		mv ifcfg-eth3 ifcfg-em4 && sed  -i "s/eth3/em4/g" ifcfg-em4

		echo "网卡文件改名配置完毕"
	fi
}

function disable_selinux()
{
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
	grep "setenforce  0"  /etc/rc.local ||echo "setenforce  0" >> /etc/rc.local
	getenforce|grep Disabled || setenforce 0
}

function get_yum()
{
	cd /etc/yum.repos.d/
	mkdir bak
	mv `ls | grep -v "bak"` bak
	yum_file=(
 		"http://10.21.100.40/script/repo/base.repo"  
		"http://10.21.100.40/script/repo/epel.repo"  
		"http://10.21.100.40/script/repo/rdo-Icehouse.repo"
		)
	result=0
	for filename in "${yum_file[@]}"; do
		wget $filename > /dev/null 
		let result=$result+$?
		echo $result
	done

	if [[ $result != 0 ]]
	then
		echo "获取源文件失败"
		exit 1
	else
		#yum clean all
		echo "获取源文件完毕"
	fi
}	

function install_pk()
{
	yum -y install $1 > /dev/null
	if [[ $? != 0 ]]
	then 
		echo "$1 安装失败"
		exit 1
	else
		echo "$1 安装完毕"
	fi
}

function start_service()
{
        service $1 start > /dev/null 
        if [[ $? != 0 ]]
        then
                echo "$1 服务启动失败"
                exit 1
        else
                echo "$1 服务启动成功"
        fi

}
function restart_service()
{
        service $1 restart > /dev/null
        if [[ $? != 0 ]]
        then
                echo "$1 服务重新启动失败"
                exit 1
        else
                echo "$1 服务重新启动成功"
        fi
}
function chkconfig_service()
{
        chkconfig $1 on > /dev/null
        if [[ $? != 0 ]]
        then
                echo "$1 服务放入开机启动失败"
                exit 1
        else
                echo "$1 服务放入开机启动成功"
        fi
}
function execute_cmd()
{
        eval $@
        [[ $? != 0 ]] && {
                echo "[execute_cmd] $@ 失败"
                exit 1
        }
        echo "[execute_cmd] $@ 成功"
        return 0
}


function keygen()
{
expect << EOF

spawn  ssh-keygen -t rsa
while 1 {

        expect {
                        "Enter file in which to save the key*" {
                                        send "\n"
                        }
                        "Enter passphrase*" {
                                        send "\n"
                        }
                        "Enter same passphrase again:" {
                                        send "\n"
                                        }

                        "Overwrite (y/n)" {
                                        send "y\n"
                        }
                        eof {
                                   exit
                        }

        }
}
EOF
}


function copy_ssh()
{
DEST=$1
PASS=$2
expect << EOF

spawn ssh-copy-id root@$DEST
while 1 {

        expect {
                        "Are you sure you want to continue connecting (yes/no)?" {
                                        send "yes\n"
                        }
                        "*password" {
                                        send "$PASS\n"
                        }
                        eof {
                                   exit
                        }

        }
}
EOF
