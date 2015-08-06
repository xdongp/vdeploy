# -*- coding:utf-8 -*-
from models import db
from sqlalchemy import and_

class Host(db.Model):
    __tablename__ = "host"
    id = db.Column(db.Integer, primary_key=True)
    hostname = db.Column(db.VARCHAR(64), nullable=False)
    ip = db.Column(db.VARCHAR(16), nullable=False)
    user = db.Column(db.VARCHAR(64), nullable=False)
    passwd = db.Column(db.VARCHAR(64), nullable=False)
    cpu_model = db.Column(db.VARCHAR(64))
    cpu_num = db.Column(db.Integer)
    mem = db.Column(db.Integer)   #单位MB
    disk = db.Column(db.Integer)   #单位MB
    interface = db.Column(db.VARCHAR(256)) #json格式
    status = db.Column(db.Boolean, default=False)


class Role(db.Model):
    """
    机器角色： 目前一台机器只支持一种角色
    """

    ROLE_CHOISE = ('control', 'compute', 'network', 'storage')

    id = db.Column(db.Integer, primary_key=True)
    host_id = db.Column(db.Integer, db.ForeignKey(Host.id), nullable=False)
    host = db.relationship(Host)
    role = db.Column(db.VARCHAR(16))

    def __init__(self, role, host_id):
        self.role = role
        self.host_id = host_id


    @classmethod
    def create_not_exist(cls, role, host_id):
        objs = cls.query.filter(and_(cls.role==role, cls.host_id==host_id)).all()
        if(len(objs)>0):
            return True
        if role not in cls.ROLE_CHOISE:
            return False
        role =  Role(role, host_id)
        db.session.add(role)
        db.session.commit()
        return True


class Deploy(db.Model):
    name = db.Column(db.VARCHAR(16), primary_key=True)
    net_model = db.Column(db.VARCHAR(8), nullable=False)
    net_manage = db.Column(db.VARCHAR(8), nullable=False)
    net_compute = db.Column(db.VARCHAR(8), nullable=False)
    net_ex = db.Column(db.VARCHAR(8), nullable=False)
    store_model = db.Column(db.VARCHAR(8), nullable=False)


    def __init__(self, name, net_model, net_manage, net_compute,  net_ex, store_model):
        self.name = name
        self.net_model = net_model
        self.net_manage = net_manage
        self.net_compute = net_compute
        self.net_ex = net_ex
        self.store_model = store_model

    @classmethod
    def create(cls, net_model, net_manage, net_compute,  net_ex, store_model):
        obj = Deploy.get()
        if obj:
           return False
        obj = Deploy("default", net_model, net_manage, net_compute,  net_ex, store_model)
        db.session.add(obj)
        db.session.commit()

    @classmethod
    def get(cls):
        return Deploy.query.filter(Deploy.name=="default").first()

    @classmethod
    def clear(cls):
        obj = Deploy.query.filter(Deploy.name=="default").first()
        if obj:
            db.session.delete(obj)
            db.session.commit()

    @classmethod
    def update(cls, dct):
        obj = Deploy.get()
        if not obj:
            return False
        for k, v in dct.items():
            attr = getattr(obj, k, None)
            if attr:
                setattr(obj, k, v)

        db.session.commit()
        return True
