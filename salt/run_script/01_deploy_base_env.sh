run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh
salt '*' state.highstate -l debug
salt '*' state.sls cml.agent_register
