#!/usr/bin/env python
# -*- coding: utf-8 -*-
__author__ = 'xdpan'

import urllib
from gevent.wsgi import WSGIServer
from views import *
import config

URL = {"/index":   viewIndex,
        "/deployall":    viewDeployAll,
        "/deployone":    viewDeployOne,
       }


def HTTPServer(request, start_response):
    body = ""
    request["QUERY"] = parseArg(request["QUERY_STRING"])
    method = URL.get(request["PATH_INFO"], "")
    if request["REMOTE_ADDR"] not in config.allow_host:
        HTTP403(start_response)
        return ""

    if not method:
        HTTP404(start_response)
    else:
        body = method(request, start_response)
        if body != "HeaderHasSend":
            start_response("200 OK", [])
    return body

def parseArg(query):
    ret = {}
    query = urllib.unquote(query)
    if query:
        lst = query.split("&")
        for e in lst:
            (k, v) = e.split("=")
            ret[k] = v
    return ret


def HTTP403(header):
    header("403 Forbidden", [])
    return "HeaderHasSend"

def HTTP404(header):
    header("404 Not Found", [])
    return "HeaderHasSend"

def HTTP500(header):
    header("500 Not Support", [])
    return "HeaderHasSend"


if __name__ == "__main__":
    print "runserver 0.0.0.0:%s" % config.port
    WSGIServer(('', config.port), HTTPServer).serve_forever()