#!/bin/bash
source ./utils.sh
source ./config.sh

execute_cmd "iptables -F"
execute_cmd "service iptables save"
#handle_network
#get_yum
disable_selinux

install_list_first=(
	"ntp"
	"mysql"
	"mysql-server"
	"MySQL-python"
	"iproute"
	"yum-plugin-priorities"
	)
install_list_second=(
	"crudini"
	"openstack-utils"
	"openstack-selinux"
	"kernel"
	)

for pk in ${install_list_first[@]}; do
	install_pk $pk
done

execute_cmd "cd /etc/yum.repos.d/ && rm -f foreman.repo puppetlabs.repo rdo-release.repo"
#execute_cmd "yum clean all"

for pk in ${install_list_second[@]}; do
	install_pk $pk
done

cat > /etc/my.cnf << EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
symbolic-links=0

default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
EOF

start_service mysqld
chkconfig_service mysqld

#grub="title CentOS (2.6.32-358.123.2.openstack.el6.x86_64)\n\troot (hd0,0)\n\tkernel /vmlinuz-2.6.32-358.123.2.openstack.el6.x86_64 ro root=/dev/mapper/vg_root-lv_root rd_NO_LUKS rd_LVM_LV=vg_root/lv_root LANG=en_US.UTF-8 rd_NO_MD SYSFONT=latarcyrheb-sun16 crashkernel=auto rd_LVM_LV=vg_root/lv_swap  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet\n\tinitrd /initramfs-2.6.32-358.123.2.openstack.el6.x86_64.img"
#execute_cmd "sed -i '/hiddenmenu/a $grub' /boot/grub/grub.conf"
execute_cmd "grep  vmlinuz-2.6.32-358.123.2.openstack.el6.x86_64 /boot/grub/grub.conf &>/dev/null"

uname -a |grep  "2.6.32-358.123.2.openstack.el6.x86_64" || reboot


install_list=(
	"rabbitmq-server"
	"openstack-keystone" 
	"python-keystoneclient"
	"openstack-glance"
	"python-glanceclient"
	"openstack-nova-api"
	"openstack-nova-cert" 
	"openstack-nova-conductor"
	"openstack-nova-console"
	"openstack-nova-novncproxy"
	"openstack-nova-scheduler"
	"python-novaclient"
	"openstack-neutron"
	"openstack-neutron-ml2"  
	"openstack-neutron-openvswitch"
	"memcached" 
	"python-memcached"
	"mod_wsgi"
	"openstack-dashboard"
)
for pk in ${install_list[@]}; do 
	install_pk $pk
done


start_service rabbitmq-server
chkconfig_service rabbitmq-server
execute_cmd "rabbitmqctl status"
execute_cmd "/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management"
restart_service rabbitmq-server 
execute_cmd "curl http://localhost:55672/mgmt/"
execute_cmd "openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:$PASS@$MYIP/keystone"

cat > /tmp/keystone.sql << EOF
use  mysql
delete from user where user="";
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO "keystone"@"localhost" IDENTIFIED BY "$PASS";

GRANT ALL PRIVILEGES ON keystone.* TO "keystone"@"%" IDENTIFIED BY "$PASS"; 
flush privileges;
EOF
execute_cmd "mysql -uroot < /tmp/keystone.sql"
execute_cmd "su -s /bin/sh -c 'keystone-manage db_sync' keystone"

execute_cmd "(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '01 * * * * /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/keystone"

execute_cmd "ADMIN_TOKEN=$(openssl rand -hex 10)"
execute_cmd "openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN"
execute_cmd "keystone-manage pki_setup --keystone-user keystone --keystone-group keystone"
execute_cmd "chown -R keystone:keystone /etc/keystone/ssl "
execute_cmd "chmod -R o-rwx /etc/keystone/ssl"
execute_cmd "export OS_SERVICE_TOKEN=$ADMIN_TOKEN"
execute_cmd "export SERVICE_TOKEN=$ADMIN_TOKEN"
execute_cmd "export OS_SERVICE_ENDPOINT=http://$MYIP:35357/v2.0"

start_service  openstack-keystone
chkconfig_service openstack-keystone

execute_cmd "keystone user-create --name=admin --pass=$PASS --email=admin@test.com"
execute_cmd "keystone role-create --name=admin"
execute_cmd "keystone tenant-create --name=admin --description='Admin Tenant'"
execute_cmd "keystone user-role-add --user=admin --tenant=admin --role=admin"
execute_cmd "keystone user-role-add --user=admin --role=_member_ --tenant=admin"
execute_cmd "keystone user-create --name=demo --pass=$PASS --email=demo@test.com"
execute_cmd "keystone tenant-create --name=demo --description='Demo Tenant'"
execute_cmd "keystone user-role-add --user=demo --role=_member_ --tenant=demo"
execute_cmd "keystone tenant-create --name=service --description='Service Tenant'"
execute_cmd "keystone service-create --name=keystone --type=identity  --description='OpenStack Identity'"
execute_cmd "keystone endpoint-create --service-id=$(keystone service-list | awk '/ identity / {print $2}')  --publicurl=http://$MYIP:5000/v2.0  --internalurl=http://$MYIP:5000/v2.0  --adminurl=http://$MYIP:35357/v2.0"

execute_cmd "unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT SERVICE_TOKEN"
execute_cmd "keystone --os-username=admin --os-tenant-name=admin --os-password=$PASS --os-auth-url=http://$MYIP:35357/v2.0 token-get"

cat > /tmp/admin_openrc.sh << EOF
export OS_USERNAME=admin
export OS_PASSWORD=$PASS
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$MYIP:35357/v2.0
EOF
execute_cmd "source /tmp/admin_openrc.sh"

execute_cmd "keystone token-get"
execute_cmd "keystone user-list"


execute_cmd "openstack-config --set /etc/glance/glance-api.conf database  connection mysql://glance:$PASS@$MYIP/glance"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf database  connection mysql://glance:$PASS@$MYIP/glance"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_host $MYIP"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_userid guest"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf DEFAULT rabbit_password guest"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$MYIP:5000"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host $MYIP"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port 35357"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password $PASS"
execute_cmd "openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$MYIP:5000"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  auth_host $MYIP"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 35357"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password $PASS"
execute_cmd "openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone"

execute_cmd "keystone user-create --name=glance --pass=$PASS  --email=glance@test.com"
execute_cmd "keystone user-role-add --user=glance --tenant=service --role=admin"
execute_cmd "keystone service-create --name=glance --type=image --description='OpenStack Image Service'"
execute_cmd "keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}')  --publicurl=http://$MYIP:9292  --internalurl=http://$MYIP:9292  --adminurl=http://$MYIP:9292"

cat > /tmp/glance.sql << EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost'  IDENTIFIED BY "$PASS";
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%'  IDENTIFIED BY "$PASS";
EOF
execute_cmd "mysql -uroot < /tmp/glance.sql"
execute_cmd "mv -f /usr/lib/python2.6/site-packages/glance/common/crypt.py ~/"
execute_cmd "ln /usr/lib64/python2.6/crypt.py /usr/lib/python2.6/site-packages/glance/common/crypt.py"
execute_cmd "su -s /bin/sh -c 'glance-manage db_sync' glance"

start_service openstack-glance-api
start_service openstack-glance-registry
chkconfig_service openstack-glance-api
chkconfig_service openstack-glance-registry

#execute_cmd "wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img"
#execute_cmd "glance image-create --name 'cirros-0.3.2-x86_64' --disk-format qcow2 --container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img"
execute_cmd "glance image-list"


execute_cmd "keystone user-create --name=nova --pass=$PASS --email=nova@test.com"
execute_cmd "keystone user-role-add --user=nova --tenant=service --role=admin"
execute_cmd "keystone service-create --name=nova --type=compute --description='OpenStack Compute'"
execute_cmd "keystone endpoint-create --service-id=$(keystone service-list | awk '/ compute / {print $2}')  --publicurl=http://$MYIP:8774/v2/%\(tenant_id\)s  --internalurl=http://$MYIP:8774/v2/%\(tenant_id\)s  --adminurl=http://$MYIP:8774/v2/%\(tenant_id\)s"

execute_cmd "openstack-config --set /etc/nova/nova.conf database connection mysql://nova:$PASS@$MYIP/nova"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_host $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_password guest"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$MYIP:5000"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $PASS"

cat > /tmp/nova.sql << EOF
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY "$PASS";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'  IDENTIFIED BY "$PASS";
EOF
execute_cmd "mysql -uroot < /tmp/nova.sql"
execute_cmd "su -s /bin/sh -c 'nova-manage db sync' nova"

start_service openstack-nova-api
start_service openstack-nova-cert
start_service openstack-nova-consoleauth
start_service openstack-nova-scheduler
start_service openstack-nova-conductor
start_service openstack-nova-novncproxy
chkconfig_service openstack-nova-api
chkconfig_service openstack-nova-cert
chkconfig_service openstack-nova-consoleauth
chkconfig_service openstack-nova-scheduler on
chkconfig_service openstack-nova-conductor on
chkconfig_service openstack-nova-novncproxy on

nova image-list || sleep 3 || nova image-list || sleep 3
execute_cmd "nova image-list"


cat > /tmp/neutron.sql << EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY "$PASS";
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY "$PASS";
flush privileges;
EOF
execute_cmd "mysql -uroot < /tmp/neutron.sql"

execute_cmd "keystone user-create --name neutron --pass $PASS --email neutron@test.com"
execute_cmd "keystone user-role-add --user neutron --tenant service --role admin"
execute_cmd "keystone service-create --name neutron --type network --description 'OpenStack Networking'"
execute_cmd "keystone endpoint-create --service-id $(keystone service-list | awk '/ network / {print $2}') --publicurl http://$MYIP:9696 --adminurl http://$MYIP:9696 --internalurl http://$MYIP:9696"

execute_cmd "sed -i 's/net.ipv4.ip_forward = [0-9]*/net.ipv4.ip_forward = 1/g'  /etc/sysctl.conf"
execute_cmd "sed -i 's/net.ipv4.conf.default.rp_filter = [0-9]*/net.ipv4.conf.default.rp_filter = 0/g'  /etc/sysctl.conf"
execute_cmd "sed -i 's/net.ipv4.conf.all.rp_filter = [0-9]*/net.ipv4.conf.all.rp_filter = 0/g' /etc/sysctl.conf"
execute_cmd "modprobe bridge"
execute_cmd "sysctl -p"

start_service openvswitch
execute_cmd "ovs-vsctl br-exists br-int ||ovs-vsctl add-br br-int"
execute_cmd "ovs-vsctl br-exists br-$TRUNKDEV ||ovs-vsctl add-br br-$TRUNKDEV"
execute_cmd "ovs-vsctl list-ports br-$TRUNKDEV|grep ^$TRUNKDEV||ovs-vsctl add-port br-$TRUNKDEV $TRUNKDEV"

cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
rabbit_host = $MYIP
rabbit_password = guest
rabbit_userid = guest

notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

auth_strategy = keystone
nova_url = http://$MYIP:8774/v2
nova_admin_username = nova
nova_admin_tenant_id = $(keystone tenant-list | awk '/ service / { print $2 }')
nova_admin_password = $PASS
nova_admin_auth_url = http://$MYIP:35357/v2.0

core_plugin = ml2
service_plugins = router

[keystone_authtoken]
auth_uri = http://$MYIP:5000
auth_host = $MYIP
auth_protocol = http
auth_port = 35357
admin_tenant_name = service
admin_user = neutron
admin_password = $PASS

[database]
connection = mysql://neutron:$PASS@$MYIP/neutron

[service_providers]
service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
EOF


cat > /etc/neutron/plugins/ml2/ml2_conf.ini << EOF
[ml2]
type_drivers = vlan
tenant_network_types = vlan
mechanism_drivers = openvswitch

[ml2_type_flat]

[ml2_type_vlan]
network_vlan_ranges = physnet1:1:4000

[ml2_type_gre]

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF

cat > /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini << EOF
[ovs]
enable_tunneling = False
integration_bridge=br-int
network_vlan_ranges = physnet1
bridge_mappings = physnet1:br-$TRUNKDEV

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF

execute_cmd "ln -s plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini"

cat > /etc/neutron/l3_agent.ini  << EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
EOF

cat > /etc/neutron/dhcp_agent.ini  << EOF
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
ovs_integration_bridge = br-int
EOF

cat > /etc/neutron/metadata_agent.ini << EOF
[DEFAULT]
auth_url = http://$MYIP:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = $PASS
nova_metadata_ip = $MYIP
metadata_proxy_shared_secret = $PASS
EOF

execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT  service_neutron_metadata_proxy true"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT  neutron_metadata_proxy_shared_secret $PASS"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$MYIP:9696"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $PASS"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$MYIP:35357/v2.0"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron"


restart_service openstack-nova-api
restart_service openstack-nova-scheduler
restart_service openstack-nova-conductor

start_service neutron-server
start_service openvswitch
start_service neutron-dhcp-agent
start_service neutron-l3-agent
start_service neutron-metadata-agent

chkconfig_service neutron-server
chkconfig_service neutron-dhcp-agent
chkconfig_service neutron-l3-agent
chkconfig_service neutron-metadata-agent
chkconfig_service openvswitch


execute_cmd "sed -i 's/horizon.example.com/*/g' /etc/openstack-dashboard/local_settings"
start_service memcached 
start_service httpd 
start_service memcached 
chkconfig_service httpd
chkconfig_service memcached

echo "^^, 控制节点安装完成"
exit 0
