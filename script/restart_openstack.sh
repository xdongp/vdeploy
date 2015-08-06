#!/bin/sh

cd /etc/init.d
service rabbitmq-server restart
for i in `ls openstack-*`; do service $i restart; done
for i in `ls neutron-*`; do service $i restart; done  
