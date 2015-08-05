#!/usr/bin/env python
# -*- coding: utf-8 -*-
#CDNAgent配置文件
import logging

logfile = "./agent.log"
logging.basicConfig(filename=logfile, level = logging.DEBUG,  format='%(asctime)s - %(levelname)s: %(message)s')

port = 22222

#文件备份目录
ats_config_bak_dir = "/Users/xdpan/tmp/bak"

#配置文件全路径
ats_config = "/Users/xdpan/tmp/a.yaml"

#ats重启命令
ats_reload = "uptime"

#回滚命名，返回0表示成功
ats_check = "ats -v"

#允许访问的IP，只能写单个IP,不能写网段
allow_host = ["1.2.3.4", "127.0.0.1"]