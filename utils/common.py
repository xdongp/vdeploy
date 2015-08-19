# -*- coding:utf-8 -*-
__author__ = 'xdpan'

import os
import paramiko
import config


def ssh2(ip, username, passwd, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip, 22, username, passwd, timeout=5)
        stdin, stdout, stderr = ssh.exec_command(cmd)
        out = stdout.readlines()
        ssh.close()
        return (True, out)
    except:
        pass
    return (False, "")

def nohup_exec(cmd):
    try:
        ret = os.system(cmd + " &")
        return True if ret == 0 else False
    except:
        pass
    return False

def exec_script(script):
    filename = "%s/%s" % (config.SCRIPT_DIR, script)
    if not os.path.exists(filename):
        return False
    # 后台执行安装
    cmd = "cd %s && sh %s &>>%s/install.log" % (config.SCRIPT_DIR, script, config.SCRIPT_DIR)
    nohup_exec(cmd)
    return True

def get_cpu_info(ip, user, passwd):
    cmd="grep 'model name' /proc/cpuinfo |tail -n 1 |awk  -F':' '{print $2}'"
    (ret, cpu_model) = ssh2(ip, user, passwd, cmd)
    cmd = "grep 'processor' /proc/cpuinfo  |wc -l"
    (ret, cpu_num) = ssh2(ip, user, passwd, cmd)
    return {"cpu_model": cpu_model[0].strip("\n"), "cpu_num": cpu_num[0].strip("\n")}

def get_mem_info(ip, user, passwd):
    cmd = "free -m|grep 'Mem' |awk  '{print $2}'"
    (ret, mem) = ssh2(ip, user, passwd, cmd)  #单位：MB
    return mem[0].strip("\n")

def get_disk_info(ip, user, passwd):
    """
    功能： 获取磁盘大小，可能会有问题
    """
    cmd = "fdisk -l|grep Disk|grep dev|awk 'BEGIN{count=0}{count+=$3}END{print count}'"
    (ret, disk) = ssh2(ip, user, passwd, cmd)  #单位：GB
    if disk:
        return disk[0].strip("\n")
    return "0"

def get_if_info(ip, user, passwd):
    cmd = "ifconfig -a | sed 's/[ \t].*//;/^$/d'"
    (ret, ifs) = ssh2(ip, user, passwd, cmd)
    lst = []
    for e in ifs:
        if e.startswith("eth") or e.startswith("em"):
            lst.append(e.strip("\n"))
    return ",".join(lst)

def check_host(ip, user, passwd):
    """
    功能：检查主机密码是否正确
    """
    (code, msg) = ssh2(ip, user, passwd, "date")
    return code

def change_hostname(ip, hostname, user, passwd):
    cmd = "sed -i 's/HOSTNAME=.*$/HOSTNAME=%s/g' /etc/sysconfig/network" % hostname
    ssh2(ip, user, passwd, cmd)
    cmd = "hostname %s" % hostname
    ssh2(ip, user, passwd, cmd)
    return True

def grant_ssh(ip, user, passwd):
    """
    功能：建立ssh信任关系
    """
    return exec_script("auth_ssh.sh %s %s" % (ip, passwd))

def get_host_info(ip, user, passwd):
    """
    功能：获取服务器信息，并返回
    """
    cpu_info = get_cpu_info(ip, user, passwd)
    mem_info = get_mem_info(ip, user, passwd)
    disk_info = get_disk_info(ip, user, passwd)
    if_info = get_if_info(ip, user, passwd)
    #grant_ssh(ip, user, passwd)
    dct = {"mem": mem_info, "disk": disk_info, "if": if_info}
    dct.update(cpu_info)
    return dct

def make_config(deploy, control, computes):
    """
    功能：生成部署配置文件
    """
    net_manage = deploy.net_manage
    net_compute = deploy.net_compute
    net_ex = deploy.net_ex
    net_model = deploy.net_model  # 暂时只支持vlan
    store_model = deploy.store_model  # 暂时不支持存储模式

    conf = """#!/bin/sh
export ROOT_DIR=/root/vdeploy
export SERVICE_URL=http://127.0.0.1:%d
export CONTROL='%s'
export COMPUTE=(%s)
export NETMODEL=%s
export NETDEV=%s
export TRUNKDEV=%s
export EXNET=%s
export STORE=%s
export PASS='verystack0okm'
export MYIP=`ifconfig $NETDEV|grep "inet addr:"|awk '{print $2}'|awk -F':' '{print $2}'`
export MYMAC=`ifconfig $NETDEV|grep HW|awk  '{print $5}'`
""" % (config.PORT, control, " ".join(computes), net_model, net_manage, net_compute, net_ex, store_model)
    filename = "%s/config.sh" % config.SCRIPT_DIR
    with open(filename, "w") as fd:
        fd.write(conf)
    return True


def backend_install():
    """
    功能：后台部署
    """
    return exec_script("install.sh")


def backend_uninstall():
    """
    功能：后台卸载
    """
    return exec_script("uninstall.sh")
