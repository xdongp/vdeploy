# -*- coding:utf-8 -*-
from flask import Blueprint
from flask import jsonify
from flask import request
from flask import redirect
from models.Deploy import *
from flask import render_template

MOD_NAME = "device"
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

@blue_print.route("/config", methods=["GET", "POST"])
def config():
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
            Deploy.create(dct["net_model"], dct["net_manage"], dct["net_compute"],  dct["net_ex"], dct["store_model"])
        return redirect("deploy")
    else:
        hosts = Host.query.all()
        deploy = Deploy.get()
        return render_template("config.html", hosts=hosts, deploy=deploy)