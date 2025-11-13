#!/bin/bash 

path_to_config_file="/usr/ot.conf.json"
if test -f ${path_to_config_file}; then
    parsed_verbose=$( jq '.verbose_by_default' --raw-output "$path_to_config_file" )
    parsed_split_pattern=$( jq '.split_pattern' --raw-output "$path_to_config_file" )
    parsed_terminal_limit=$( jq '.default_terminal_limit' --raw-output "$path_to_config_file" )
    parsed_extra_title=$( jq '.default_extra_title' --raw-output "$path_to_config_file" )
    parsed_profile=$( jq '.default_profile' --raw-output "$path_to_config_file" )
    parsed_join_open=$( jq '.open_terminals_together_by_default' --raw-output "$path_to_config_file" )
    parsed_log_file=$( jq '.log_file' --raw-output "$path_to_config_file" )
    parsed_user=$( jq ".default_user" --raw-output "$path_to_config_file" )
    parsed_pass=$( jq ".default_pass" --raw-output "$path_to_config_file" )
    parsed_autocomplete_ip=$( jq ".autocomplete_ip" --raw-output "$path_to_config_file" )
    parsed_autocomplete_by_defult=$( jq ".autocomplete_by_default" --raw-output "$path_to_config_file" )
else
    echo "Warning --> Config file not found"
    parsed_verbose="null"
    parsed_split_pattern="null"
    parsed_terminal_limit="null"
    parsed_extra_title="null"
    parsed_profile="null"
    parsed_join_open="null"
    parsed_log_file="null"
    parsed_user="null"
    parsed_pass="null"
    parsed_autocomplete_ip="null"
    parsed_autocomplete_by_defult="null"
fi

#path_to_json_config_file="/usr/ot.conf.json"

#Parsed configs from the json config file

#Configurable params
[[ "$parsed_verbose" != "null" ]] && verbose="$parsed_verbose" || verbose=false 
[[ "$parsed_log_file" != "null" ]] && log_file="$parsed_log_file" || log_file="/var/log/ot.log" 
[[ "$parsed_split_pattern" != "null" ]] && split_pattern="$parsed_split_pattern" || split_pattern="grid" 
[[ "$parsed_terminal_limit" != "null" ]] && terminal_limit="$parsed_terminal_limit" || terminal_limit=5 
[[ "$parsed_extra_title" != "null" ]] && terminal_extra_title="$parsed_extra_title" || terminal_extra_title="" 
[[ "$parsed_profile" != "null" ]] && terminator_profile="$parsed_profile" || terminator_profile="Default" 
[[ "$parsed_join_open" != "null" ]] && join_open="$parsed_join_open" || join_open=false 
[[ "$parsed_user" != "null" ]] && default_user="$parsed_user" || default_user="root" 
[[ "$parsed_pass" != "null" ]] && default_pass="$parsed_pass" || default_password="" 
[[ "$parsed_autocomplete_ip" != "null" ]] && autocomplete_ip="$parsed_autocomplete_ip" || autocomplete_ip="" 
[[ "$parsed_autocomplete_by_default" != "null" ]] && autocomplete="$parsed_autocomplete_by_defult" || autocomplete=false


comment(){
    if $verbose; then
        echo $@
    fi
}

if [[ -f "$log_file" ]]; then
    comment "Log file exist"
else
    comment "Log file does not exist"
    touch "$log_file"
fi

Log(){
    echo "$(date) -- $@" >> "$log_file" 
}
Log "=====OT init====="

#Non-configurable params(for now)
available_vms=""
auto_authenticate=true
if $autocomplete; then
    DEFAULT=false
    if [[ "$autocomplete_ip" == "" ]]; then
        echo "WARNING: Autocomplete feature is enabled but no autocomplete_ip is provided by the config file, check config file"
    fi
else
    DEFAULT=true
fi
terminals_to_open=()

Log "Parameters: Split pattern --> $split_pattern || Verbose --> $verbose || Terminal limit --> $terminal_limit || Default extra title --> $terminal_extra_title || Default profile --> $terminator_profile || Open together --> $join_open"

Help(){
    cat <<'____HALP'
____________________________
ot --> Open Terminal Command
----------------------------

Synopsis:
A script to easily open and connect terminator terminals to VMs

Usage: ot [-h ] [-n NUMBER_OF_TERMINALS ] [-j(v,h,g) TERMINAL_NUMBER ]
          [-t TITLE ] [-v ]

OPTIONS:
    -v, --verbose                           Shows all comments

    -h, --help                              Shows help page

    -n <NUMBER_OF_TERMINALS>                Adds n amount of terminals in one go

    -j/--join <TERMINAL_NUMBER>             Opens all terminals in the same window with the default split pattern

    -jv/--joinv <TERMINAL_NUMBER>           Opens all terminals in the same window with vertical split pattern

    -jh/--joinh <TERMINAL_NUMBER>           Opens all terminals in the same window with horizontal split pattern

    -jg/--joing <TERMINAL_NUMBER>           Opens all terminals in the same window with grid split pattern

    -t/--title <TITLE>                      Adds extra text to the title of the terminal

    --see                                   Shows the current vms on the mcahine and thir IPs

    --no-auth                               The srcipt will not try to use the default password, it will be asked from the user

    --default                               Ignores the configuration and restores the default behaviour to open terminals using the configured nicknames

CONFIGURATION:

    Config file default location --> /usr/ot.conf.json

____HALP
}


Find_connection_id(){
    nickname="$1"
    conn_id=$( jq ".nicknames | .\"$nickname\"" --raw-output "$path_to_config_file" )
    echo "$conn_id"
}


Get_connection_command(){
    terminal=$1
    connection_username="$default_user"
    connection_password="$default_pass"
    if $autocomplete; then
        connection_ip="$autocomplete_ip$terminal"
    else
        connection_ip=$terminal
    fi

    #hardcoded Execptions --
    [[ $terminal = 121 ]] && connection_password="password123"

    if $DEFAULT; then
        connection_id=$(Find_connection_id $terminal)
        if [[ "$connection_id" == "null" ]]; then
            Log "ERROR: nickname $terminal not found in the configured nicknames, check the configuration or use the non-default mode"
            echo "echo 'FATAL ERROR: the nickname [ $terminal ] is not registered in the config file, check spelling and config file' ; sleep 5"
            return
        fi
        connection_ip=$( jq ".connections | .\"$connection_id\" | .ip" --raw-output "$path_to_config_file" )
        if [[ "$connection_ip" == "null" ]]; then
            Log "ERROR: connection $connection_id does not have a configured ip, check the configuration or use the non-default mode"
            echo "echo 'FATAL ERROR: the selected connection ($connection_id) does NOT have an ip configured, please check the config file' ; sleep 5"
            return
        fi
        connection_username=$( jq ".connections | .\"$connection_id\" | .user" --raw-output "$path_to_config_file" )
        connection_password=$( jq ".connections | .\"$connection_id\" | .password" --raw-output "$path_to_config_file" )
        if [[ "$connection_username" == "null" ]]; then
            Log "Warning: no username defined for that nickname, using default username"
            connection_username="$default_user"
            #connection_username=$( jq ".default_user" --raw-output "$path_to_config_file" )
        fi
        if [[ "$connection_password" == "null" ]]; then
            Log "Warning: no password defined for that nickname, using default password"
            connection_password="$default_pass"
        fi
    fi

    Log "Command: Connecting to $connection_username@$connection_ip password --> $connection_password"
    if $auto_authenticate; then
        echo "echo 'Connecting to $connection_username@$connection_ip' ; sshpass -p '$connection_password' ssh $connection_username@$connection_ip"
    else
        echo "echo 'Connecting to $connection_username@$connection_ip' ; ssh $connection_username@$connection_ip"
    fi
}

# Update this check for "-/--" unnecessary now
Get_conn_ip(){
    conns=("|")
    for terminal in ${terminals_to_open[@]}
    do
        case $terminal in
            -*|--*)
                ;;
            *)
                conns+="$terminal|"
                ;;
        esac
    done
    echo "$conns"
}


Process_title(){
    terminal=$1
    only_extra=${terminal_extra_title:0:1}

    if [[ "$only_extra" = "-" ]]; then
        echo ${terminal_extra_title:1}
    else
        echo "${terminal_extra_title} $terminal"
    fi
}


Find_terminal(){
    title="$@"
    Log "Finding terminal ---> $title   //"
    all_terminals=($(remotinator get_terminals))
    for terminal in ${all_terminals[@]}
    do
        if [[ "$terminal" = "None" ]]; then
            continue
        fi
        terminal_title=($(remotinator --uuid $terminal get_window_title | tr " " "\n" ))
        #Log "Checking terminal $terminal_title == $title"
        if [[ "$title" = "${terminal_title[0]}" ]];then
            echo "$terminal"
            return 0
        fi
    done
    Log "Terminal: $terminal  --not found"
    return 1
}


Split_terminals(){
    uuids=($1)
    i=1
    split_vertical=1
    split_count=1
    #split_type="hsplit"
    get_split_type=""

    case $split_pattern in
        grid|fibonacci)
            get_split_type='test "$split_vertical" -eq 1 && echo vsplit || echo hsplit'
            ;;
        vertical)
            get_split_type='echo vsplit'
            ;;
        horizontal)
            get_split_type='echo hsplit'
            ;;
        *)
            Log "Split pattern not found"
            exit 1
            ;;
    esac
        
    Log "Splitting terminals // $split_pattern"
    Log "${terminals_to_open[@]}"
    Log "--------------------------------------"
    Log "Initial uuid --> ${uuids[0]}"
    Log "======================================"

    while [[ $i < "${#terminals_to_open[@]}" ]]; do
        
        terminal=${terminals_to_open[$i]}
        command_to_execute=$(Get_connection_command "$terminal")
        
        split_type=$(eval "$get_split_type")

        #Log "Oppening terminal $terminal with uuid --> ${uuids[0]} // split type --> $split_type"
        new_uuid=($(remotinator --uuid ${uuids[0]} "$split_type" -T "$terminal"  -x "$command_to_execute"))
        #Log ""
        #Log "Terminal splitted, result uuid --> ${new_uuid[0]}" 
        uuids+=(${new_uuid[0]})
        uuids=("${uuids[@]:1}" "${uuids[0]}") #nice
        #Log "Total of uuids:"
        #Log "${uuids[@]}"
        ((split_count--))
        if [[ $split_count -eq 0 ]]; then
            [[ $split_vertical -eq 1 ]] && split_vertical=0 || split_vertical=1
            split_count="${#uuids[@]}"
        fi
        #Log "--split end--"

        ((i++))
    done
}

Open_together(){
    join_title="$(Get_conn_ip)"

    #We find if there is already a terminal opened with that title, since we get the uuid of the terminal via de window title, we need the join terminals to have unique titles
    title_num=0
    og_join_title=$join_title
    while Find_terminal "$join_title";
    do
        ((title_num++))
        comment "Duplicated title --> $title_num"
        join_title="$og_join_title~$title_num" #If we have a duplicated title we add ~n ti te title to keep it unique
    done

    join_title="${terminal_extra_title}${join_title}"
    first_bash_command=$(Get_connection_command "${terminals_to_open[0]}") #We get the connection command for the first terminal we open, the parent of all the rest
    terminator -p "$terminator_profile" -T "$join_title" -x "$first_bash_command"
    comment "finding terminal $join_title"
    uuid="$(Find_terminal "${join_title[@]}")"
    comment "uuid --> $uuid"
    Log "Terminal found! uuid --> $uuid"
    Log "Split pattern switch: pattern selected --> $split_pattern"
    Split_terminals $uuid
}

See_avaiable_machines(){
    if [[ "$available_vms" == "" ]]; then
        echo "No available VMs"
    else
        i=1
        for entry in "${available_vms[@]}"; do
            vm_name_uuid=($(echo $entry | tr -d "}" | tr "{" " "))
            vm_name=${vm_name_uuid[0]}
            vm_uuid=${vm_name_uuid[1]}
            vm_details=($(vboxmanage showvminfo --details $vm_uuid | grep "Attachment: Host-only Interface" | tr -d " " | tr "," ":" | tr ":" " "))
            mac_address=${vm_details[2]}
            vm_ip=($(vboxmanage dhcpserver findlease --interface vboxnet0 --mac-address=$mac_address | head -1))
            echo "[$i] $vm_name --> IP: ${vm_ip[2]}"
            ((i++))
        done
    fi
}

Get_available_vms(){
    available_vms=($(vboxmanage list runningvms | tr -d " "))
}


Test(){
    comment "Verbose!"
    Log "Test --!"
    echo "=== Testing ==="


    sleep 3
    echo "Test done"
}


while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            echo "Testing . . ."
            Test $2 
            exit 0
            ;;
        -s | --separated)
            comment "Setting join_open to False"
            join_open=false
            ;;
        --see)
            Get_available_vms
            See_avaiable_machines
            exit 0
            shift
            ;;
        -v|--verbose)
            verbose=true #Shows comments
            shift
            ;;
        --no-auth)
            Log "Setting auto authenticate to false"
            auto_authenticate=false
            shift
            ;;
        -n)
            number_to_add=$2
            if [[ $number_to_add -gt $terminal_limit ]]; then
                echo "You probably didn't meant $number_to_add . . ."
                number_to_add=$terminal_limit  #Max number to add should probably be a configurable parameter(it now is)

            fi
            comment "Adding --> $3 X $number_to_add"
            for i in $(seq $number_to_add)
            do
                terminals_to_open+=("$3")
            done
            shift 3
            ;;
        -h|--help)
            Help
            exit 0
            shift
            ;;
        -j|--join)
            Log "Setting join_open to True"
            join_open=true
            shift # past join option
            ;;
        -jv|--joinv)
            Log "Setting join_pattern to vertical"
            join_open=true
            split_pattern="vertical"
            shift # past join option
            ;;
        -jh|--joinh)
            Log "Setting join_pattern to horizontal"
            join_open=true
            split_pattern="horizontal"
            shift # past join option
            ;;
        -jg|--joing)
            Log "Setting join_pattern to grid"
            join_open=true
            split_pattern="grid"
            shift # past join option
            ;;
        -t|--title)
            Log "Switching extra title from [ $terminal_extra_title ] to [ $2 ]"
            terminal_extra_title="$2"
            shift 2
            ;;
        --default)
            Log "Warning: default mode enabled, nickname use enabled and turned on by default"
            DEFAULT=true
            shift # past not done yet
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            Log "Adding ot --> $1"
            terminals_to_open+=("$1") # save terminal number/nickname
            shift 
            ;;
    esac
done

if [[ ${#terminals_to_open[@]} -eq 0 ]]; then 
    echo "Select a terminal from your system:"
    Get_available_vms
    See_avaiable_machines
    read -p "--> " selected_vm
    ((selected_vm--))
    if [[ "${available_vms[$selected_vm]}" == "" ]]; then
        echo "Error, please select from the available machines"
        exit 1
    fi
    vm_name_uuid=($(echo ${available_vms[$selected_vm]} | tr -d "}" | tr "{" " "))
    vm_uuid=${vm_name_uuid[1]}
    vm_details=($(vboxmanage showvminfo --details $vm_uuid | grep "Attachment: Host-only Interface" | tr -d " " | tr "," ":" | tr ":" " "))
    mac_address=${vm_details[2]}
    vm_ip=($(vboxmanage dhcpserver findlease --interface vboxnet0 --mac-address=$mac_address | head -1))
    vm_ip="${vm_ip[2]}"
    auto_authenticate=false
    autocomplete=false
    command_to_execute=$(Get_connection_command "$vm_ip")
    terminator -T "${vm_name_uuid[0]}" -p "$terminator_profile" -x "$command_to_execute"
    exit 0
fi

if $join_open; then
    comment "Opening together:"
    comment "${terminals_to_open[@]}"
    Open_together
    exit 0
fi

Log "Opening separate terminals: ${terminals_to_open[@]}"
for terminal in ${terminals_to_open[@]}
do
    title=$(Process_title $terminal)
    command_to_execute=$(Get_connection_command "$terminal")
    terminator -T "$title" -p "$terminator_profile" -x "$command_to_execute"
done



