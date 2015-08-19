# -*- coding:utf-8 -*-
from threading import Lock
import os


g_deploy_lock = Lock()
g_deploy_status = 0


DEBUG = False
ROOT_DIR = "/Users/xdpan/PycharmProjects/vdeploy"
#ROOT_DIR=os.path.dirname(os.path.abspath("__file__"))
LOG_DIR = "%s/log" % ROOT_DIR
SCRIPT_DIR = "%s/script" % ROOT_DIR

SQLALCHEMY_DATABASE_URI = "sqlite:///%s/vdeploy.db" % ROOT_DIR



