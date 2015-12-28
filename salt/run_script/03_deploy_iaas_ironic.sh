run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh

salt-run state.sls packstack.deploy_iaas_ironic -l info
salt '*' cmd.run "chmod -R 777 /var/lib/glance" > /dev/null  2>&1 || exit 0
salt '*' cmd.run "chmod -R 777 /var/lib/nova/instances" > /dev/null  2>&1 || exit 0
salt 'cc*' cmd.run "systemctl restart openstack-glance-api" &>/dev/null || exit 0

rtv=$?
if [ $rtv -eq 0 ];then
    sleep 5
    echo "uploading ironic images..........."
    bash /opt/software/other/uploadironic.sh all /opt/software/ironic_images 1
fi

