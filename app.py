#-*- coding:utf-8 -*-
import sys, traceback
from base import app
from flask import render_template
from flask import redirect
from flask.ext import admin
from flask_admin.contrib import sqla
from flask_debugtoolbar import DebugToolbarExtension

app.debug = False
app.config['SECRET_KEY'] = "123456"
app.config['DEBUG_TB_INTERCEPT_REDIRECTS'] = False
toolbar = DebugToolbarExtension(app)

from models import db
from models.deploy import *

#Blueprint导入
from views.deploy import blue_print as deploy_bp

admin = admin.Admin(app, name=u'Deploy Admin')
admin.add_view(sqla.ModelView(Host, db.session, name=u"主机"))

#注册bp
app.register_blueprint(deploy_bp, url_prefix="")



@app.route('/')
def index():
    return redirect("/deploy")

@app.before_request
def before_request():
    print "-- in blue_print app"

@app.errorhandler(Exception)
def exception_handler(e):
    exc_type, exc_value, exc_traceback = sys.exc_info()
    info = traceback.format_exception(exc_type, exc_value, exc_traceback)
    err_msg = "\n".join(info)
    print err_msg

@app.errorhandler(404)
def page_not_found(e):
        return render_template('404.html'), 404

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)
