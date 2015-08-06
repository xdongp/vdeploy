#!/bin/bash
source  ./install_openstack_lib.sh 
source ./config.sh

install_list=(
	"openstack-nova-compute"
	"libvirt"
	"openstack-neutron"
	"openstack-neutron-ml2"
	"openstack-neutron-openvswitch"
	"xfsprogs"
	)

for pk in ${install_list[@]}; do
        install_pk $pk
done


execute_cmd "openstack-config --set /etc/nova/nova.conf database connection mysql://nova:$PASS@$CONTROL/nova"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$CONTROL:5000"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_host $CONTROL"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_protocol http"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_port 35357"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_user nova"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service"
execute_cmd "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $PASS"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_host $CONTROL"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_password guest"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_max_retries 0"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MYIP"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled True"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$CONTROL:6080/vnc_auto.html"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT glance_host $CONTROL"
execute_cmd "openstack-config --set /etc/nova/nova.conf libvirt virt_type kvm"

start_service libvirtd
start_service messagebus
start_service openstack-nova-compute
chkconfig_service libvirtd
chkconfig_service messagebus
chkconfig_service openstack-nova-compute

execute_cmd "sed -i 's/net.ipv4.conf.default.rp_filter = [0-9]*/net.ipv4.conf.default.rp_filter = 0/g'  /etc/sysctl.conf"
execute_cmd "sed -i 's/net.ipv4.conf.all.rp_filter = [0-9]*/net.ipv4.conf.all.rp_filter = 0/g' /etc/sysctl.conf"
execute_cmd "modprobe bridge"
execute_cmd "sysctl -p"

cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
rabbit_host = $CONTROL
rabbit_password = guest
rabbit_userid = guest

notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True

auth_strategy = keystone
nova_url = http://$CONTROL:8774/v2
nova_admin_username = nova
nova_admin_password = $PASS
nova_admin_auth_url = http://$CONTROL:35357/v2.0

core_plugin = ml2
service_plugins = router

[keystone_authtoken]
auth_uri = http://$CONTROL:5000
auth_host = $CONTROL
auth_protocol = http
auth_port = 35357
admin_tenant_name = service
admin_user = neutron
admin_password = $PASS


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

execute_cmd "rm -f /etc/neutron/plugin.ini"
execute_cmd "ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini"

start_service neutron-openvswitch-agent
start_service openvswitch
chkconfig_service openvswitch
chkconfig_service neutron-openvswitch-agent

execute_cmd "ovs-vsctl br-exists br-int||ovs-vsctl add-br br-int"
execute_cmd "ovs-vsctl br-exists br-$TRUNKDEV||ovs-vsctl add-br br-$TRUNKDEV"
execute_cmd "ovs-vsctl list-ports br-$TRUNKDEV|grep ^$TRUNKDEV||ovs-vsctl add-port br-$TRUNKDEV $TRUNKDEV"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$CONTROL:9696"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_auth_strategy keystone"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name service"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_username neutron"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $PASS"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$CONTROL:35357/v2.0"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver"
execute_cmd "openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron"



restart_service openstack-nova-compute
restart_service neutron-openvswitch-agent

#execute_cmd "parted /dev/sdb -s mklabel gpt"
#execute_cmd "parted /dev/sdb -s mkpart primary 0% 100%"
#execute_cmd "mkfs.xfs /dev/sdb1"
#execute_cmd "echo '/dev/sdb1 /var/lib/nova/instances xfs defaults 0 0' >> /etc/fstab"
#execute_cmd "mount -t xfs /dev/sdb1 /var/lib/nova/instances"
#execute_cmd "chown -R nova:nova /var/lib/nova/instances/"

echo "^^, 计算节点安装完成"
exit 0
