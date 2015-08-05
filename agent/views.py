#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'xdpan'

from config import logging
import config
import shutil
import os
import time
import json
import globals

index = 0

G_BACKEND_STATUS = False


def viewIndex(request, header):
    return "VDeployAgent 1.0.0"

def viewDeployAll(request, header):
    data = request['QUERY'].get("data", "")
    #env = json.loads(data)

    if not globals.BACKEND_STATUS:
        globals.BACKEND_STATUS = True
        #开始部署
        return "deploy all env"
    else:
        return "deploy all env exist"

def viewDeployOne(request, header):
    global index
    index += 1
    return "deploy one %d" % index

def viewDeployStatus(request, header):
    global index
    index += 1
    return "deploy one %d" % index






