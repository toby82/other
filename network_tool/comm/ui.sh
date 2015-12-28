function UI_confirmYesOrNo() {
    local confirmMsg=$1
    local deault=$2
    read -p  "${confirmMsg} (y/n):(${deault})" _input
    [ "$_input" = "" ] && _input="${deault}"
    until [ "$_input" = 'n' -o "$_input" = "y" ];do
        UI_confirmYesOrNo "$confirmMsg" "$deault"
    done 
    if [ "$_input" = "y" ];then
        echo "y"
    else
        echo "n"
    fi
}

function UI_save(){
    _in_save=$(UI_confirmYesOrNo "Save it?" "y")
    case "$_in_save" in
        "y")
            echo "Saving ..."
            sleep 1
            return 1
            ;;
        "n")
            echo "Discard ..."
            sleep 1
            return 0
            ;;
    esac
}

function UI_pleaseWait(){
    echo $1
    echo "  * Press any key to continue *  "
    read
}

function UI_getInput() {
    local msg=$1
    local isRequired=$2
    local check_function_str=$3
    read -p "${msg}" _input
    if [ "$isRequired" = "required" ];then
        until [ -n "$_input" ];do
            UI_getInput "$msg" "$isRequired" "$check_function_str"
            return
        done
    elif [ -z "$_input" ];then
        _input="$isRequired"
    fi
    if [ -n "$check_function_str" -a "$_input" != "$isRequired" ];then
        eval "$check_function_str \"$_input\""
        rtv=$?
        until [ $rtv -eq 1 ];do
            msg=${msg#*Input error! }
            UI_getInput "Input error! $msg" "$isRequired" "$check_function_str"
            return
        done
    fi
    echo $_input
}

function UI_selection(){
    IFS=':'
    PS3="Please choose the number: "
    local ui_items=$1
	select select_item in $ui_items; do 
        if [ $select_item ];then
		    echo $select_item
            return
		fi
    done 
}

function printAllNic(){
    local count=`ip addr show | grep -v "lo" | grep qdisc | awk '{print $2'}`
    echo "------------------------------------------"
    echo -e "Network Interface    \tIP"
    echo "------------------------------------------"
    for i in $count;do
		ip=`ip addr show $i | awk '/inet / {split($2,x,"/");print x[1]}'`
		echo -e "$i               \t$ip"
	done
    echo "------------------------------------------"
}

function checkInputNic(){
    local _in_nic=$1
    if [ "$_in_nic" = "" ];then
        return 0
    fi
    local count=`ip addr show |grep qdisc | awk '{print $2'} | egrep "\b${_in_nic}\b"`
    if [ "$count" = "" ];then
        return 0
    fi
    return 1
}

function UI_setSingeNetInterface(){
    echo ""
    echo "Here is the list for the Network Interface below:"
    printAllNic
    _in_nic=$(UI_getInput "Please enter the Network Interface: ")
    checkInputNic $_in_nic
    if [ $? -eq 0 ];then
        echo "Input error! Plese input Network Interface from list"
        UI_pleaseWait
        clear
        UI_setSingeNetInterface
    fi
}

function UI_setMultiNetInterface(){
    echo ""
    echo "Here is the list for the Network Interface below:"
    printAllNic
    _in_muti_nic=$(UI_getInput "Please enter the mutiple Network Interfaces(Exam:eth0 eth1): ")
    local count=0
    local flag=""
    for tmpNic in $_in_muti_nic;do
        checkInputNic $tmpNic
        if [ $? -eq 0 ];then
            echo "Input error! Plese input Network Interfaces from list"
            flag="error"
            break
        else
            (( count++ ))
        fi
    done
    if [ "$flag" = "error" ];then
        UI_pleaseWait
        clear
        UI_setMultiNetInterface
    elif [ "$_in_muti_nic" = "" -o $count -lt 2 ];then
        echo "Input error! The count of the Network Interfaces >= 2"
        UI_pleaseWait
        clear
        UI_setMultiNetInterface
    fi
}

function UI_setMultiMod(){
    _in_mode=$(UI_getInput "Please enter the bond mode(0,1,2,3,4,5,6): ")
    if [ "$_in_mode" = "0" -o "$_in_mode" = "1" -o "$_in_mode" = "2" -o "$_in_mode" = "3" -o  "$_in_mode" = "4" -o "$_in_mode" = "5" -o "$_in_mode" = "6" ];then
        return
    else
        UI_setMultiMod
    fi
}
