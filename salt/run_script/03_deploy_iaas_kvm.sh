run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh

salt-run state.sls packstack.deploy_iaas_kvm -l info 
salt '*' state.sls ncha.init
salt '*' cmd.run "chmod -R 777 /var/lib/glance" > /dev/null  2>&1 || exit 0
salt '*' cmd.run "chmod -R 777 /var/lib/nova/instances" > /dev/null  2>&1 || exit 0
salt 'cc*' cmd.run "systemctl restart openstack-glance-api" &>/dev/null || exit 0
salt 'cc*' state.sls heat_docker.install

