#!/bin/bash
source ./install_openstack_lib.sh

execute_cmd "iptables -F"
execute_cmd "service iptables save"
#handle_network
get_yum
disable_selinux

install_list_first=(
	"ntp"
	"MySQL-python"  
	"iproute"
	"yum-plugin-priorities"
	)

for pk in ${install_list_first[@]}; do 
	install_pk $pk
done


execute_cmd "cd /etc/yum.repos.d/ && rm -f foreman.repo puppetlabs.repo rdo-release.repo"
#execute_cmd "yum clean all"

install_list_second=(
	"crudini"
	"openstack-utils"
	"openstack-selinux"
	"kernel"
	)

for pk in ${install_list_second[@]}; do 
	install_pk $pk
done

#grub="title CentOS (2.6.32-358.123.2.openstack.el6.x86_64)\n\troot (hd0,0)\n\tkernel /vmlinuz-2.6.32-358.123.2.openstack.el6.x86_64 ro root=/dev/mapper/vg_root-lv_root rd_NO_LUKS rd_LVM_LV=vg_root/lv_root LANG=en_US.UTF-8 rd_NO_MD SYSFONT=latarcyrheb-sun16 crashkernel=auto rd_LVM_LV=vg_root/lv_swap  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet\n\tinitrd /initramfs-2.6.32-358.123.2.openstack.el6.x86_64.img"
#execute_cmd "sed -i '/hiddenmenu/a $grub' /boot/grub/grub.conf"
execute_cmd "grep  vmlinuz-2.6.32-358.123.2.openstack.el6.x86_64 /boot/grub/grub.conf &>/dev/null"

uname -a |grep  "2.6.32-358.123.2.openstack.el6.x86_64" || reboot
