#-*- coding:utf-8 -*-
from models import db
from models.deploy import *

db.drop_all()
db.create_all()