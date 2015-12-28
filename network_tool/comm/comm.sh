export PATH_DEPLOY="/opt/software/deploy"
export DEPLOY_ROLE_FLAG="$PATH_DEPLOY/server_master"
export MASTER_SERVER_NAME="autodeploy"
export COLUMNS=100

tty | egrep "pts" && stty erase ^H

function changeLineOrAddToLastLine(){
    filePath="$1"
    oldlineContext="$2"
    newlineContext="$3"

    count=`/bin/egrep "$oldlineContext" "$filePath" | wc -l`
    if [ $count -eq 0 ];then
        # 添加到末尾
        echo "${newlineContext}" >> "$filePath"
    else
        # 修改
        oldlineContext=$(echo "${oldlineContext}" |sed -e 's/\//\\\//g' )
        oldlineContext=$(echo "${oldlineContext}" |sed -e 's/\&/\\\&/g' )
        newlineContext=$(echo "${newlineContext}" |sed -e 's/\//\\\//g' )
        newlineContext=$(echo "${newlineContext}" |sed -e 's/\&/\\\&/g' )
        sed -i "s/.*${oldlineContext}.*/${newlineContext}/g" "$filePath"
    fi
}

function isMasterRole(){
    [ -e "$DEPLOY_ROLE_FLAG"] && return 1
    return 0
}
    
function check_ip(){
    echo $1 |grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null 2>&1
    rtv=$? 
    if [ $rtv -eq 1 ];then
        return 0
    else
    	for var in `echo $1 | awk -F. '{print $1, $2, $3, $4}'`;do
    		if [ $var -ge 0 -a $var -le 255 ];then
    			continue
    		else
    			return 0
    		fi
    	done
    fi
    # Check OK
    return 1
}

function check_set_datetime(){
    local input="$1"
    echo "$input" | grep "^[0-9]\{1,4\}-[0-9]\{1,2\}-[0-9]\{1,2\} [0-9]\{1,2\}:[0-9]\{1,2\}$" > /dev/null 2>&1
    if [ $? -eq 1 ];then
        return 0
    else
    	date -s "$input"
        [ $? -ne 0 ] && return 0
    fi
    # Check and set is OK
    /sbin/hwclock -w
    return 1    
}

function is_dev_setup_with_ip(){
    local count=$(ip -o addr show | egrep "\binet\b" | grep -v "127.0.0.1" | wc -l)
    if [ $count -ge 1 ];then
        return 1
    else
        return 0
    fi
}
    

# chkconfig salt-minion off
# chkconfig salt-master off
# 
# /etc/hosts manager_server
# 
# chkconfig libvirtd off
function set_hostname(){
    local name=$1
    touch "/etc/sysconfig/network"
    changeLineOrAddToLastLine "/etc/sysconfig/network" "HOSTNAME=" "HOSTNAME=${name}"
    hostname $name
    service salt-minion status
    local rtv=$?
    # 停止服务
    [ $rtv -eq 0 ] && service salt-minion stop
    
    if [ -e /etc/salt/minion_id ];then
        echo "${name}" > /etc/salt/minion_id
    fi
    
    # 启动服务
    service salt-minion start
}

function setHostName(){
	local name=${1}
	hostname ${name}
	if [ -x /usr/bin/hostnamectl ];then
            /usr/bin/hostnamectl --static set-hostname ${name}
	    return 1
	else
	    return 0 
	fi
}


function set_master(){
    # hosts修改
    local master_ip=$1    
    
    # 配置HOSTS文件
    changeLineOrAddToLastLine "/etc/hosts" "$MASTER_SERVER_NAME" "$master_ip        $MASTER_SERVER_NAME"
    if [ -e /usr/bin/salt-master ];then
        systemctl enable  salt-master
        systemctl restart salt-master
    fi    
    if [ -e /usr/bin/salt-minion ];then
        systemctl enable  salt-minion
        systemctl restart salt-minion
    fi
    
}

function check_env(){
    echo
}

# setNetwork -dev "eth0" -model "static" -mod "0" -ip "1.1.1.1" -mask "255.255.255.255" -gw "2.2.2.2" -dns "3.3.3.3"
function set_net_ifcfg(){
    local dev model mod ip mask gw dns master
    while [ -n "$1" ] ; do
        if [[ "$1" == -* ]] && [[ "$2" != -* ]];then
            case "$1" in
                "-dev")     dev=$2;;
                "-model")   model=$2;;
                "-mod")     mod=$2;;
                "-ip")      ip=$2;;
                "-mask")    mask=$2;;
                "-gw")      gw=$2;;
                "-dns")     dns=$2;;
                "-master")  master=$2;;
            esac
        fi
        shift 1
    done
    ifcfg_path="/etc/sysconfig/network-scripts/ifcfg-${dev}"
    cat << EOF > "${ifcfg_path}"
DEVICE=$dev
TYPE=Ethernet
ONBOOT=yes
IPV6INIT=no
USERCTL=no
NM_CONTROLLED=no
EOF

    if [ "${model,,}" = "static" ];then
        #配置 static
        echo "BOOTPROTO=static" >> "${ifcfg_path}"
        [ "$ip" != "" ]   && echo "IPADDR=$ip"    >> "${ifcfg_path}"
        [ "$mask" != "" ] && echo "NETMASK=$mask" >> "${ifcfg_path}"
        [ "$gw" != "" ]   && echo "GATEWAY=$gw"   >> "${ifcfg_path}"
        [ "$dns" != "" ]  && echo "DNS1=$dns"     >> "${ifcfg_path}"

    elif [ "${model,,}" = "dhcp" ];then
        #配置 dhcp
        echo "BOOTPROTO=dhcp" >> "${ifcfg_path}"
    else
        echo "BOOTPROTO=none" >> "${ifcfg_path}"
    fi
    [ "$master" != "" ] && echo "master=$master"  >> "${ifcfg_path}"
}

function setNetwork(){
    local dev model mod ip mask gw dns 
    local bondname="bond"
    while [ -n "$1" ];do
        if [[ "$1" == -* ]] && [[ "$2" != -* ]];then
            case "$1" in
                "-dev")   dev=$2;;
                "-model") model=$2;;
                "-mod")   mod=$2;;
                "-ip")    ip=$2;;
                "-mask")  mask=$2;;
                "-gw")    gw=$2;;
                "-dns")   dns=$2;;
            esac
        fi
        shift 1
    done
 
    if [ "$mod" = "" ];then
    # 设置single
        set_net_ifcfg -dev "$dev" -model "$model" -ip "$ip" -mask "$mask" -gw "$gw" -dns "$dns"
    else
    # 设置bond
        #生成master bond名字
        for devname in $dev;do
            bondname="${bondname}${devname##*eth}"
        done
        #设置master卡
        set_net_ifcfg -dev "$bondname" -model "$model" -ip "$ip" -mask "$mask" -gw "$gw" -dns "$dns"
        #设置slave卡
        for devname in $dev;do
            set_net_ifcfg -dev "$devname" -model "none" -master "$bondname"
        done
        bonding_cfg="/etc/modprobe.d/bonding.conf"
        touch "$bonding_cfg"
        line1="alias $bondname bonding"
        line2="options $bondname miimon=100 mode=${mod}"
        changeLineOrAddToLastLine "$bonding_cfg" "alias $bondname" "$line1"
        changeLineOrAddToLastLine "$bonding_cfg" "options $bondname" "$line2"
        [ "$mod" = "1" ] && changeLineOrAddToLastLine "/etc/rc.d/rc.local" "ifenslave $bondname" "ifenslave $bondname $dev"
    fi
    
    service network restart
    [ "$mod" = "1" ] && ifenslave $bondname $dev
    
    chkconfig libvirtd on
    service libvirtd restart
    
    if [ -e /etc/init.d/salt-minion ];then
        chkconfig salt-minion on
        grep "$MASTER_SERVER_NAME" /etc/hosts > /dev/null 2>&1 && service salt-minion restart
    fi
    if [ -e /etc/init.d/salt-master ];then
        chkconfig salt-master on
        service salt-master restart
    fi
}

function set_dhcpNetwork(){
     ifcfg_path="/etc/sysconfig/network-scripts/ifcfg-${_in_nic}"
    cat << EOF > "${ifcfg_path}"
DEVICE=$_in_nic
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
ONBOOT=yes
IPV6INIT=no
USERCTL=no
NM_CONTROLLED=no
EOF
echo -e "Network Interface: $_in_nic  \nmodel: $_in_model"
sleep 5
}
