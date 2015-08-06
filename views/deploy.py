# -*- coding:utf-8 -*-
from flask import Blueprint
from flask import request
from flask import redirect
from flask import render_template
from flask import jsonify

from models.deploy import *

from utils.common import *
import config


MOD_NAME = "deploy"
blue_print = Blueprint(MOD_NAME, MOD_NAME, template_folder="templates", static_folder="static")


@blue_print.before_request
def before_request():
    print '---in blue_print %s' % MOD_NAME


@blue_print.route("/")
def list():
    hosts = Host.query.all()
    return render_template("hosts.html", hosts=hosts)


@blue_print.route("/deploy")
def deploy():
    hosts = Host.query.all()
    deploy = Deploy.get()
    role = Role.query.join(Host).all()
    return render_template("deploy.html", hosts=hosts, deploy=deploy, role=role)


@blue_print.route("/logs")
def logs():
    hosts = Host.query.all()
    deploy = Deploy.get()
    role = Role.query.join(Host).all()
    return render_template("hosts.html", hosts=hosts, deploy=deploy, role=role)


@blue_print.route("/clear")
def clear():
    hosts = Host.query.all()
    Deploy.clear()
    roles = Role.query.all()
    for role in roles:
        db.session.delete(role)
    db.session.commit()
    return redirect("/deploy")


@blue_print.route("/setconfig", methods=["GET", "POST"])
def setConfig():
    if request.method == "POST":
        print request.form
        dct = {}
        compute = request.form.getlist("compute")
        control = request.form.get("control")

        dct["net_model"] = request.form.get("net-model")
        dct["net_manage"] = request.form.get("net-manage")
        dct["net_compute"] = request.form.get("net-compute")
        dct["net_ex"] = request.form.get("net-ex")
        dct["store_model"] = request.form.get("store-model")
        print dct

        if control:
            Role.create_not_exist('control', control)
        for item in compute:
            Role.create_not_exist('compute', item)

        obj = Deploy.get()
        if obj:
            Deploy.update(dct)
        else:
            Deploy.create(dct["net_model"], dct["net_manage"], dct["net_compute"], dct["net_ex"], dct["store_model"])
        return redirect("deploy")
    else:
        hosts = Host.query.all()
        deploy = Deploy.get()
        return render_template("config.html", hosts=hosts, deploy=deploy)


@blue_print.route("/installall", methods=["GET", "POST"])
def installAll():
    with config.g_deploy_lock:
        if not config.g_deploy_status:
            config.g_deploy_status = True
            # 开始部署, 后台操作
            deploy = Deploy.get()
            role = Role.query.join(Host).all()
            control = ""
            compute = []
            for e in role:
                if e.role == "control":
                    control = e.host.ip
                elif e.role == "compute":
                    compute.append(e.host.ip)

            makeConfig(deploy, control, compute)
            grantSsh()
            backendInstall()
            return "deploy all env"
        else:
            return "deploy all env exist"


@blue_print.route("/installone", methods=["GET", "POST"])
def installOne():
    with config.g_deploy_lock:
        if not config.g_deploy_status:
            # 开始部署, 后台操作
            #makeConfig(env)
            #backendInstall()
            return "deploy all env"
        else:
            return "deploy all env exist"


@blue_print.route("/startinstall", methods=["GET", "POST"])
def startInstall():
    if not config.g_deploy_status:
        config.g_deploy_status = True
        return jsonify({'status': 'succ'})
    else:
        return jsonify({'status': 'fail'})


@blue_print.route("/finishinstall", methods=["GET", "POST"])
def finishInstall():
    if config.g_deploy_status:
        config.g_deploy_status = False
        return jsonify({'status': 'succ'})
    else:
        return jsonify({'status': 'fail'})


