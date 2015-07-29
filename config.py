# -*- coding:utf-8 -*-
import os

DEBUG = False
ROOT_DIR = os.path.dirname(os.path.abspath("__file__"))
LOG_DIR = "%s/log" % ROOT_DIR

#SQLALCHEMY_DATABASE_URI = "sqlite:///%s/vdeploy.db" % ROOT_DIR
SQLALCHEMY_DATABASE_URI = "sqlite:////Users/xdpan/PycharmProjects/vdeploy/vdeploy.db"


print SQLALCHEMY_DATABASE_URI



