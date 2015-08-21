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


# ########################## views #############################
@blue_print.route("/login", methods=["GET", "POST"])
def login_view():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        if username == "admin" and password == "admin":
            return redirect("/")

        return render_template("login.html", error=True)
    return render_template("login.html")


@blue_print.route("/")
def index_view():
    hosts = Host.query.all()
    dct = {"host": 0, "cpu": 0, "mem": 0, "disk": 0}
    for host in hosts:
        dct["host"] += 1
        dct["cpu"] += host.cpu_num
        dct["mem"] += host.mem / 1000
        dct["disk"] += host.disk / 1000

    return render_template("hosts.html", hosts=hosts, stat=dct, name=u"首页", link="/")


@blue_print.route("/deploy")
def deploy_view():
    hosts = Host.query.all()
    deploy = Deploy.get()
    role = Role.query.join(Host).all()
    return render_template("deploy.html", hosts=hosts, deploy=deploy, role=role, name=u"部署")


@blue_print.route("/config", methods=["GET", "POST"])
def config_view():
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
        role = Role.query.join(Host).all()
        idle = []
        role_ids = []
        interfaces = []
        for h in role:
            role_ids.append(h.host.id)
        for h in hosts:
            interfaces.extend(h.interface.split(","))
            if h.id not in role_ids:
                idle.append(h)

        interfaces = {}.fromkeys(interfaces).keys()
        interfaces = sorted(interfaces)
        return render_template("config.html", hosts=hosts, deploy=deploy, role=role, idle=idle, interfaces=interfaces,
                               name=u"配置")


@blue_print.route("/logs")
def logs_view():
    f = "%s/script/install.log" % config.ROOT_DIR
    logs = []
    print f
    try:
        with open(f) as fd:
            logs = fd.readlines()
            logs = [log.strip("\n").decode("utf-8") for log in logs]
    except:
        raise
    return render_template("logs.html", logs=logs, line=len(logs), name=u"日志")


@blue_print.route("/status")
def status_view():
    keystone = check_keystone_service()
    glance = check_glance_service()
    nova = check_nova_service()
    neutron = check_neutron_service()
    return render_template("status.html", keystone=keystone, glance=glance, nova=nova, neutron=neutron, name=u"状态")


@blue_print.route("/monitor")
def monitor_view():
    deploy = Deploy.get()
    host = Role.query.filter(Role.role=="control").first()
    if host:
        control = host.host.ip
    else:
        control = "127.0.0.1"
    return render_template("monitor.html", deploy=deploy, control=control,  name=u"监控")

@blue_print.route("/about")
def about_view():
    return render_template("about.html", name=u"关于")


####################### end views ####################


####################### ajax   #######################
@blue_print.route("/ajax_val_ip", methods=["POST", "GET"])
def ajax_val_ip():
    if request.method == "POST":
        ip = request.form.get("ip")
        exist = Host.query.filter(Host.ip == ip).all()
        if exist:
            return '{"valid": false}'

        # 验证ssh端口
        if is_open(ip, 22):
            return '{"valid": true}'
    return '{"valid": false}'


@blue_print.route("/ajax_get_logs", methods=["GET"])
def ajax_get_logs():
    if request.method == "GET":
        line = request.args.get("line", -1, type=int)
        if line < 0:
            return ""

        f = "%s/script/install.log" % config.ROOT_DIR
        try:
            with open(f) as fd:
                logs = fd.readlines()
                dct = {"line": len(logs), "data": "".join(logs[line:])}
                return jsonify(dct)
        except:
            raise
    return ""


@blue_print.route("/ajax_clear_logs", methods=["GET"])
def ajax_clear_logs():
    f = "%s/script/install.log" % config.ROOT_DIR
    try:
        with open(f, "w") as fd:
            fd.write("")
            return jsonify({"status": "succ"})
    except:
        raise
    return jsonify({"status": "fail"})


####################### end ajax #####################

####################### api   ########################

@blue_print.route("/api/reset")
def api_reset():
    hosts = Host.query.all()
    for host in hosts:
        host.progress = 0
    Deploy.clear()
    roles = Role.query.all()
    for role in roles:
        db.session.delete(role)
    db.session.commit()
    return redirect("/deploy")


@blue_print.route("/api/host/add", methods=["GET", "POST"])
def api_host_add():
    if request.method == "POST":
        hostname = request.form.get("hostname")
        ip = request.form.get("ip")
        passwd = request.form.get("passwd")
        exist = Host.query.filter(Host.ip == ip).all()
        if exist:
            return jsonify({'status': 'fail', 'msg': u'主机已经存在'})

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


@blue_print.route("/api/host/del", methods=["GET"])
def api_host_del():
    host_id = request.args.get("id", type=int)
    if host_id:
        host = Host.query.get(host_id)
        db.session.delete(host)
        db.session.commit()
    return redirect("/")


@blue_print.route("/api/host/addrole")
def api_host_addrole():
    role = request.args.get("role")
    ids = request.args.get("ids")
    print role, ids
    if not role or not ids:
        return "error", 400

    for id in ids.split(","):
        Role.create_not_exist('compute', int(id))
    return "succ"


@blue_print.route("/api/install/all", methods=["GET", "POST"])
def api_install_all():
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
            # grant_ssh(hosts)
            backend_install()
            return jsonify({'status': 'succ', 'msg': u'执行成功'})
        else:
            return jsonify({'status': 'fail', 'msg': u'部署已存在'})


@blue_print.route("/api/install/one", methods=["GET", "POST"])
def api_install_one():
    id = request.args.get("id", -1, type=int)
    if id < 0:
        return jsonify({"status": "fail"})
    host = Host.query.get(id)
    if not host:
        return jsonify({"status": "fail"})
    role = Role.query.filter(Role.host_id == id).first()
    if role.role == "compute":
        backend_install_compute(host.ip)
    elif role.role == "control":
        backend_install_control(host.ip)
    else:
        return jsonify({"status": "fail"})
    return jsonify({"status": "succ"})


@blue_print.route("/api/reinstall/one", methods=["GET", "POST"])
def api_reinstall_one():
    id = request.args.get("id", -1, type=int)
    if id < 0:
        return jsonify({"status": "fail"})
    host = Host.query.get(id)
    if not host:
        return jsonify({"status": "fail"})
    role = Role.query.filter(Role.host_id == id).first()
    if role.role == "compute":
        backend_reinstall_compute(host.ip)
    elif role.role == "control":
        backend_reinstall_control(host.ip)
    else:
        return jsonify({"status": "fail"})
    return jsonify({"status": "succ"})


@blue_print.route("/api/progress", methods=["GET"])
def progress():
    progress = request.args.get("progress", -1, type=int)
    print progress
    if progress < 0 or progress > 100:
        return jsonify({'status': 'fail'})
    Deploy.update_progress(progress)
    return jsonify({'status': 'succ'})


@blue_print.route("/api/progress/get", methods=["GET"])
def api_get_progress():
    dct = {}
    obj = Deploy.get()
    if obj:
        dct["main"] = obj.progress

    hosts = hosts = Host.query.all()
    for host in hosts:
        dct[host.hostname] = host.progress
    return jsonify(dct)


@blue_print.route("/api/host/progress", methods=["GET", "POST"])
def api_host_progress():
    progress = request.args.get("progress", -1, type=int)
    ip = request.args.get("ip", "")
    if not ip or progress < 0 or progress > 100:
        return jsonify({'status': 'fail'})
    Host.update_progress(ip, progress)
    return jsonify({'status': 'succ'})


####################### end api #####################
