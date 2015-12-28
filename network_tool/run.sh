#!/bin/bash
cd $(dirname $0)
export WORKSPACE=$(pwd)
source ./comm/comm.sh
source ./comm/ui.sh

##################################
#              Main              #
##################################

#--------------------------------------------------
#·一级菜单
#  ·二级菜单
#--------------------------------------------------
#·Hostname
#  ·Please enter hostname
#·Network
#  ·Single
#   ·Plese input Network Interface
#   ·Select STATIC/DHCP
#   ·Please enter IP
#   ·Please enter the netmask
#   ·Please enter the Gateway
#   ·Please enter the DNS
#  ·Bond
#   ·Plese input Network Interface
#   ·Please enter the bond mode(0,1,2,3,4,5,6)
#   ·Select STATIC/DHCP
#   ·Please enter IP
#   ·Please enter the netmask
#   ·Please enter the Gateway
#   ·Please enter the DNS
#·Autodeploy Server
#   ·Please input the IP of the Autodeploy Server
#   · {IF_IS_MASTER} Please input the datetime for the Autodeploy Server
#·Return Main Menu
#--------------------------------------------------

while [ true ];do
    clear
    cat << EOF
Welcome to use the tool for setting OS network!
You could use it to set Hostname, IP, Autodeploy Server for this OS.

Warning:
If setting OS without this tool, you must run some commands manually.

Note:
You can run it again at this way:
  sh /opt/software/network_tool/run.sh 

EOF
    echo "Please choose what you want to set: "
    # 一级菜单
    result=$( UI_selection "Hostname:Network:Autodeploy Server:Quit" );
    case "$result" in
    "Hostname" )
        # 二级级菜单
        clear
        echo -e "\n######## MENU $result ########"
        _in_hostname=$(UI_getInput "Please enter hostname: " "required")
        UI_save
        [ $? -eq 1 ] && setHostName $_in_hostname
        [ -e /etc/salt/minion_id ] && /bin/rm -f /etc/salt/minion_id
        systemctl status salt-minion && systemctl restart salt-minion
        ;;
    "Network" )
        # 二级级菜单
        clear
        echo -e "\n######## MENU $result ########"
        result=$( UI_selection "Single:Return Main Menu" );
        _in_nic=""; _in_muti_nic=""; _in_mode=""; _in_model=""; _in_ip=""; _in_mask=""; _in_gw=""; _in_dns=""
        case "$result" in
        "Single" )
            UI_setSingeNetInterface
            ;;
        "Bond" )
            UI_setMultiNetInterface
            UI_setMultiMod
            ;;
        "Return Main Menu")
            continue
            ;;
        esac
        echo "Select the IP model you want to set:"
        _in_model=$( UI_selection "STATIC:DHCP" );
        if [ "$_in_model" = "STATIC" ]; then
            _in_ip=$(UI_getInput "Please enter IP: " "required" "check_ip")
            _in_mask=$(UI_getInput "Please enter the netmask:(default 255.255.255.0) " "255.255.255.0" "check_ip")
            _in_gw=$(UI_getInput "Please enter the Gateway: " "" "check_ip")
            _in_dns=$(UI_getInput "Please enter the DNS: " "" "check_ip")
            clear
            # Check List
            echo "Here is your input below:"
            echo "------------------------------"
            echo -e "Network Interface: $_in_nic $_in_muti_nic \nModel: $_in_model"
            [ -n "$_in_mode" ] && echo "Bond Mode: $_in_mode"
            echo -e "IP: $_in_ip \nMask: $_in_mask \nGateway: $_in_gw \nDNS: $_in_dns"

            UI_save
            if [ $? -eq 1 ] && [  "$_in_mode" = ""  ];then
                setNetwork -dev $_in_nic $_in_muti_nic -model $_in_model -ip $_in_ip -mask $_in_mask -gw $_in_gw -dns $_in_dns
            elif [ $? -eq 1 ] && [  "$_in_mode" != ""  ];then
                setNetwork -dev $_in_nic $_in_muti_nic -model $_in_model -mod $_in_mode -ip $_in_ip -mask $_in_mask -gw $_in_gw -dns $_in_dns
            fi

        else
            set_dhcpNetwork && systemctl restart network
        fi


        ;;

    "Autodeploy Server" )
        # 二级级菜单
        clear
        echo -e "\n######## MENU Set Autodeploy Server ########"
        echo "The Autodeploy Server will be use for deploying、managing CC NC in IaaS."
        _in_master_ip=$(UI_getInput "Please input the IP of the Autodeploy Server: " "required" "check_ip")
        if [ -x /usr/bin/salt-master ];then
            datestr=$(date +"%Y-%m-%d %H:%M")
            _in_datetime=$(UI_getInput "Please input the new datetime if you want to change. (Now is $datestr): " "$datestr" "check_set_datetime")
        fi
        UI_save
        if [ $? -eq 1 ];then
            set_master $_in_master_ip
            sed -i '/.*network_tool.*run.sh$/d' /etc/profile
        fi
        ;;

    "Quit" )
        clear
        echo -e "\n######## MENU Quit ########"
        echo "Note:"
        echo "You can run it again at this way:"
        echo "  sh /opt/software/network_tool/run.sh"
        echo ""
        echo "Bye."
        echo ""
        exit 0
        ;;
    esac
done
