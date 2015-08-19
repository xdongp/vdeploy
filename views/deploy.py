# -*- coding:utf-8 -*-
from flask import Blueprint
from flask import request
from flask import redirect
from flask import render_template
from flask import jsonify

from models.deploy import *
from utils.common import *
import config

import socket


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
    f = "%s/script/install.log" % config.ROOT_DIR
    logs = []
    try:
        with open(f) as fd:
            logs = fd.readlines()
            logs = [log.strip("\n").decode("utf-8") for log in logs]
    except:
        pass
    return render_template("logs.html", logs=logs)


@blue_print.route("/clear")
def clear():
    hosts = Host.query.all()
    for host in hosts:
        host.progress = 0
    Deploy.clear()
    roles = Role.query.all()
    for role in roles:
        db.session.delete(role)
    db.session.commit()
    return redirect("/deploy")


@blue_print.route("/setconfig", methods=["GET", "POST"])
def set_config():
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


@blue_print.route("/install/all", methods=["GET", "POST"])
def install_all():
    with config.g_deploy_lock:
        deploy = Deploy.get()
        if not deploy:
            return "deploy not exist"
        if deploy.progress <= 0:
            Deploy.update_progress(1)
            # 开始部署, 后台操作
            role = Role.query.join(Host).all()
            hosts = Host.query.all()
            control = ""
            compute = []
            for e in role:
                if e.role == "control":
                    control = e.host.ip
                elif e.role == "compute":
                    compute.append(e.host.ip)

            make_config(deploy, control, compute)
            #grant_ssh(hosts)
            backend_install()
            return "deploy all env"
        else:
            return "deploy all env exist"


@blue_print.route("/install/one", methods=["GET", "POST"])
def install_one():
    with config.g_deploy_lock:
        deploy = Deploy.get()
        if deploy.progress <= 0:
            Deploy.update_progress(1)
            # 开始部署, 后台操作
            # makeConfig(env)
            #backendInstall()
            return "deploy all env"
        else:
            return "deploy all env exist"


@blue_print.route("/progress", methods=["GET"])
def progress():
    progress = request.args.get("progress", -1, type=int)
    print progress
    if progress < 0 or progress > 100:
        return jsonify({'status': 'fail'})
    Deploy.update_progress(progress)
    return jsonify({'status': 'succ'})


@blue_print.route("/progress/get", methods=["GET"])
def get_progress():
    dct = {}
    obj = Deploy.get()
    if obj:
        dct["main"] = obj.progress

    hosts = hosts = Host.query.all()
    for host in hosts:
        dct[host.hostname] = host.progress
    return jsonify(dct)


@blue_print.route("/host/progress", methods=["GET", "POST"])
def host_progress():
    progress = request.args.get("progress", -1, type=int)
    ip = request.args.get("ip", "")
    if not ip or progress < 0 or progress > 100:
        return jsonify({'status': 'fail'})
    Host.update_progress(ip, progress)
    return jsonify({'status': 'succ'})


@blue_print.route("/host/add", methods=["GET", "POST"])
def host_add():
    if request.method == "POST":
        hostname = request.form.get("hostname")
        ip = request.form.get("ip")
        passwd = request.form.get("passwd")
        host = Host(hostname, ip, "root", passwd)

        ret = check_host(host.ip, host.user, passwd)
        if not ret:
            return jsonify({'status': 'fail', 'msg': 'check host fail'})

        grant_ssh(host.ip, host.user, host.passwd)
        change_hostname(host.ip, host.hostname, host.user, host.passwd)

        dct = get_host_info(host.ip, host.user, host.passwd)
        host.cpu_model = dct['cpu_model']
        host.cpu_num = dct['cpu_num']
        host.mem = dct['mem']
        host.disk = dct['disk']
        host.interface = dct['if']
        db.session.add(host)
        db.session.commit()
        return jsonify({'status': 'succ'})
    else:
        return "GET method not support"

@blue_print.route("/host/del", methods=["GET"])
def host_del():
    host_id = request.args.get("id", type=int)
    if host_id:
        host = Host.query.get(host_id)
        db.session.delete(host)
        db.session.commit()
    return redirect("/")

def is_open(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.settimeout(5)
        s.connect((ip, int(port)))
        s.shutdown(2)
        return True
    except:
        return False


@blue_print.route("/ajax_val_ip", methods=["POST"])
def ajax_val_ip():
    if request.method == "POST":
        ip = request.form.get("ip")
        # 验证ssh端口
        if is_open(ip, 22):
            return '{"valid": true}'
    return '{"valid": false}'
