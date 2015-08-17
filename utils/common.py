# -*- coding:utf-8 -*-
__author__ = 'xdpan'

import subprocess
import thread
import os
import config


def nohupExec(cmd):
    try:
        #pid = os.fork()
        #if pid == 0:  #子进程
            os.system(cmd + " &")
    except:
        pass


def grantSsh(hosts):
    """
    功能：建立ssh信任关系
    """
    script="""#!/usr/bin/env bash
source ./install_openstack_lib.sh
keygen"""
    for host in hosts:
        script += "\nauto_ssh %s %s" % (host.ip, host.passwd)

    filename = "%s/auth_ssh.sh" % config.SCRIPT_DIR
    with open(filename, "w") as fd:
        fd.write(script)
    return True

def makeConfig(deploy, control, computes):
    """
    功能：生成部署配置文件
    """
    net_manage = deploy.net_manage
    net_compute = deploy.net_compute
    net_ex = deploy.net_ex
    net_model = deploy.net_model  #暂时只支持vlan
    store_model = deploy.store_model  #暂时不支持存储模式

    conf = """
#!/bin/sh
export SERVICE_URL=http://127.0.0.1:8080
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
""" % (control, " ".join(computes), net_model, net_manage, net_compute, net_ex, store_model)
    filename = "%s/config.sh" % config.SCRIPT_DIR
    with open(filename, "w") as fd:
        fd.write(conf)
    return True


def backendInstall():
    """
    功能：后台部署
    """
    filename = "%s/config.sh" % config.SCRIPT_DIR
    if not os.path.exists(filename):
        return False
    #后台执行安装
    cmd = "cd %s && sh test.sh >/tmp/install.log" % config.SCRIPT_DIR
    nohupExec(cmd)
    return True


def backendUninstall():
    """
    功能：后台卸载
    """
    filename = "%s/config.sh" % config.SCRIPT_DIR
    if not os.path.exists(filename):
        return False
    #后台执行安装
    cmd = "uninstall"
    os.system(cmd)
    return True