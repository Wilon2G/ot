#!/bin/bash 

# USE VM like name as default nick

#Configurable params default values
verbose=false 
log_file="/var/log/ot.log" 
split_pattern="grid" 
terminal_limit=5 
terminal_extra_title="" 
terminator_profile="Default" 
join_open=false 
default_user="root" 
default_pass="" 
autocomplete_ip="" 
auto_authenticate=true


: '
 --- Operational mode types ---
Default/nicknames --> 0
Autocomplete --> 1
Full IP/see & select --> 2
'
OPER_MODE=0
WIRESHARK_MODE=false

path_to_config_file="/etc/ot.conf.json"
if test -f ${path_to_config_file}; then
    #Parsed configs from the json config file
    parsed_verbose=$( jq '.verbose_by_default' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_split_pattern=$( jq '.split_pattern' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_terminal_limit=$( jq '.default_terminal_limit' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_extra_title=$( jq '.default_extra_title' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_profile=$( jq '.default_profile' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_join_open=$( jq '.open_terminals_together_by_default' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_log_file=$( jq '.log_file' --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_user=$( jq ".default_user" --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_pass=$( jq ".default_pass" --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_autocomplete_ip=$( jq ".autocomplete_ip" --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_autocomplete_by_defult=$( jq ".autocomplete_by_default" --raw-output "$path_to_config_file" 2>/dev/null )
    parsed_authenticate=$( jq ".authenticate_by_default" --raw-output "$path_to_config_file" 2>/dev/null )
    
    if [[ "$parsed_authenticate" != "null" ]]; then
        auto_authenticate="$parsed_authenticate"
    fi
    if [[ "$parsed_verbose" != "null" ]]; then
        verbose="$parsed_verbose"
    fi
    if [[ "$parsed_log_file" != "null" ]]; then
        log_file="$parsed_log_file"
    fi
    if [[ "$parsed_split_pattern" != "null" ]]; then
        split_pattern="$parsed_split_pattern"
    fi
    if [[ "$parsed_terminal_limit" != "null" ]]; then
        terminal_limit="$parsed_terminal_limit"
    fi
    if [[ "$parsed_extra_title" != "null" ]]; then
        terminal_extra_title="$parsed_extra_title"
    fi
    if [[ "$parsed_profile" != "null" ]]; then
        terminator_profile="$parsed_profile"
    fi
    if [[ "$parsed_join_open" != "null" ]]; then
        join_open="$parsed_join_open"
    fi
    if [[ "$parsed_user" != "null" ]]; then
        default_user="$parsed_user"
    fi
    if [[ "$parsed_pass" != "null" ]]; then
        default_pass="$parsed_pass"
    fi
    if [[ "$parsed_autocomplete_ip" != "null" ]]; then
        autocomplete_ip="$parsed_autocomplete_ip"
    fi
    if [[ "$parsed_autocomplete_by_default" != "null" ]]; then
        autocomplete="$parsed_autocomplete_by_defult"
        if $autocomplete; then
            OPER_MODE=1
        fi
    fi
else
    echo "Warning --> Config file not found"
fi

if [[ -f "$log_file" ]]; then
    if $verbose; then
        echo "Log file exist"
    fi
else
    if $verbose; then
        echo "Log file does not exist, creating log file $log_file . . ."
    fi
    touch "$log_file"
fi

Log(){
    echo "$(date) -- $@" >> "$log_file" 

    if $verbose; then
        echo "$(date) -- $@" >&2
    fi
}
Log "=====OT init====="

#Non-configurable params(for now)
show_all=false
available_vms=""
vm_ips=()

# If the operational mode is 1 (autocomplete ip) we check the "autocomplete_ip" field of the configuration 
if [[ $OPER_MODE -eq 1 ]]; then
    
    # If autocomplete_ip is blank it means that there is no autocomplete ip configured 
    if [[ "$autocomplete_ip" == "" ]]; then
        # Trying to use ot with autocomplete and without a configured autocomplete_ip param will result in a fatal error
        Log "ERROR: Autocomplete feature is enabled but no autocomplete_ip is provided by the config file, check config file"
        echo "ERROR: Autocomplete feature is enabled but no autocomplete_ip is provided by the config file, check config file"
        exit 1
    else
        # If we do have a configured autocomplete ip we still check that it is in the recomended format
        valid_autocomplete_ip=$(echo "$autocomplete_ip" | grep -E "^[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.$")
        if [[ "$valid_autocomplete_ip" == "" ]]; then
            # Not having the correct format on the autocomplete_ip param will result in a warning but no error
            Log "WARNING: Autocomplete feature is enabled but the configured ip is not the recomended format: [ xxx.xxx.xxx. ] -Check config file"
            echo "WARNING: Autocomplete feature is enabled but the configured ip is not the recomended format: [ xxx.xxx.xxx. ] -Check config file"
        fi
    fi
fi

terminals_to_open=()

Log "Parameters: Split pattern --> $split_pattern || Verbose --> $verbose || Terminal limit --> $terminal_limit || Default extra title --> $terminal_extra_title || Default profile --> $terminator_profile || Open together --> $join_open || Auto Authenticate --> $auto_authenticate"

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
    --- Debug ---
    -h, --help                              Shows help page

    -v, --verbose                           Shows logs

    --- Terminal Options ---
    -n <NUMBER_OF_TERMINALS>                Adds n amount of terminals in one go

    -j, --join <TERMINAL_NUMBER>            Opens all terminals in the same window with the default split pattern

    -jv, --joinv <TERMINAL_NUMBER>          Opens all terminals in the same window with vertical split pattern

    -jh, --joinh <TERMINAL_NUMBER>          Opens all terminals in the same window with horizontal split pattern

    -jg, --joing <TERMINAL_NUMBER>          Opens all terminals in the same window with grid split pattern

    -t, --title <TITLE>                     Adds extra text to the title of the terminal

    --- Virtual Machines ---
    --see                                   Shows the current available vms on the machine and their IPs

    --see-all                               Shows the current available and no avalable vms on the machine and thir IPs/MAC adresses

    --- Authentication ---
    --no-auth                               The srcipt will not try to use the default password, it will be asked from the user

    --- Operational Mode ---
    -d, --default                           Ignores the configuration and restores the default behaviour to open terminals using the configured nicknames

    -a, --autocomplete                      Ignores the configuration and sets the autocomplete mode ON. Disables DEFAULT mode

    --full-ip                               Ignores the configuration and disables both autocomplete and default modes - might as well just use ssh

    --- Command Mode ---
    -w                                      Executes a wireshark pcap on the terminal to the selected connection [in develpment]

    --- Configuration ---
    -c, --show-config                       Shows the configuration of the ot command

    -k, --nickname                          Shows the configured nicknames and their connections

CONFIGURATION FILE:
    Config file default location --> /usr/ot.conf.json

CONFIGURATION PARAMS:
    default_extra_title                     Sets a title that is displayed with the terminal title, can be overwritten eith the -t/--title option

    open_terminals_together_by_default      When true it will open all the terminals passed to ot in join mode using the default split pattern, can be 
                                            overwitten with the -s/--separated option

    default_profile                         Selects the default profile for the terminator terminals

    default_terminal_limit                  Sets a limit on the ammount of terminals you can add to ot with the -n option to prevent accidents

    split_pattern                           Sets the default split patter that will be used when using the -j/--join options. The options are "grid", "vertical", "horizontal" 

    default_user                            Sets the user that will be used when using the autocomplete mode to sshpass to the vm

    default_pass                            Sets the password that will be used when using the autocomplete mode to sshpass to the vm

    autocomplete_ip                         Sets the ip section that is added to the ip for the autocomplete connection when the sshpass 
                                            is executed the ip is <autocomplete_ip><terminal_input_by_user>

    autocomplete_by_default                 Sets the autocomplete feature on/off by default

    authenticate_by_default                 If true, ot will attempt to authenticate the ssh client with whatever credentials it has configured

    nicknames                               When the default connection mode is used, ot will look for the configured nicknames on the configuration file, 
                                            and grab their connectio_id in order to lookup the connection data. Several nicknames can have the same connection_id

    connections                             Connections are configured with a connection_id and some connection data. The connection data must 
                                            include the complete ip of the vm that we want that connection to use. The connection can also have a
                                            username, password and title configured, if not, the default_user and the default_pass will be used instead

____HALP
}

Find_connection_id(){
: '
 --- Connection ID Search ---
Given a nickname this function queries the configuration file searchig the connection ID of the nickname.
If a nickname is correctly configured in the configuration file this function will return the connection ID of that nickname.
If a nickname is not in the configuration file or it is incorrectly configured this function will return null.
'
    nickname="$1"
    Log "Find_connection_id() -- Looking for the connection id of nickname: [ $1 ] . . ."
    conn_id=$( jq ".nicknames | .\"$nickname\"" --raw-output "$path_to_config_file" )
    Log "Find_connection_id() -- Result: [ $conn_id ] . . ."
    echo "$conn_id"
}

Get_connection_command(){
    terminal=$1
    connection_username="$default_user"
    connection_password="$default_pass"
    connection_auto_auth=$auto_authenticate

    if [[ $OPER_MODE -eq 0 ]]; then

        connection_id=$(Find_connection_id $terminal)
        if [[ "$connection_id" == "null" ]]; then
            Log "Get_connection_command() -- ERROR: nickname $terminal not found in the configured nicknames, check the configuration or use the non-default mode"
            echo "echo 'FATAL ERROR: the nickname [ $terminal ] is not registered in the config file, check spelling and config file' ; sleep 5"
            return
        fi
        connection_ip=$( jq ".connections | .\"$connection_id\" | .ip" --raw-output "$path_to_config_file" )
        if [[ "$connection_ip" == "null" ]]; then
            Log "Get_connection_command() -- ERROR: connection $connection_id does not have a configured ip, check the configuration or use the non-default mode"
            echo "echo 'FATAL ERROR: the selected connection ($connection_id) does NOT have an ip configured, please check the config file' ; sleep 5"
            return
        fi
        
        connection_username=$( jq ".connections | .\"$connection_id\" | .user" --raw-output "$path_to_config_file" )
        if [[ "$connection_username" == "null" ]]; then
            Log "Get_connection_command() -- Warning: no username defined for that nickname, using default username"
            connection_username="$default_user"
            #connection_username=$( jq ".default_user" --raw-output "$path_to_config_file" )
        fi

        #Check if the connection is configured to auto authenticate
        check_configured_auth=$( jq ".connections | .\"$connection_id\" | .auth" --raw-output "$path_to_config_file" )
        if [[ "$check_configured_auth" != "null" ]]; then
            #If a connection is specifically configured with an auto-authentication value the general auto_authenticate get's overwritten for this connection
            connection_auto_auth=$check_configured_auth
        fi

        #If configured to auto authenticate the function tries to fetch the password
        if $connection_auto_auth ; then
            connection_password=$( jq ".connections | .\"$connection_id\" | .password" --raw-output "$path_to_config_file" )
            #If there is no configured password the connection password is set back to the default password
            if [[ "$connection_password" == "null" ]]; then
                Log "Get_connection_command() -- Warning: no password defined for that nickname, using default password"
                connection_password="$default_pass"
            fi
        fi

    elif [[ $OPER_MODE -eq 1 ]]; then

        connection_ip="$autocomplete_ip$terminal"

    elif [[ $OPER_MODE -eq 2 ]]; then

        connection_ip=$terminal

    else
        Log "Get_connection_command() -- Error: Unknown operational mode $OPER_MODE"
        exit 1
    fi

    if $WIRESHARK_MODE; then

        Log "WIRESHARK command in progress . . ."
        echo "echo 'Connecting to $connection_username@$connection_ip' ; sshpass -p '$connection_password' ssh $connection_username@$connection_ip 'tcpdump -i any not port ssh -s0 -w -' | wireshark -k -i- -ogui.window_title:$connection_ip"
    else
        Log "Get_connection_command() -- Command: Connecting to $connection_username@$connection_ip password --> $connection_password"
        if $connection_auto_auth; then
            echo "echo 'Connecting to $connection_username@$connection_ip' ; sshpass -p '$connection_password' ssh $connection_username@$connection_ip"
        else
            echo "echo 'Connecting to $connection_username@$connection_ip' ; ssh $connection_username@$connection_ip"
        fi
    fi

}

#Joins the terminals into one string
Get_join_title(){
    Log "Get_join_title() -- Joining titles . . ."
    conns=$(echo ${terminals_to_open[@]} | tr " " "|")
    echo "$conns"
}

Process_title(){
: '
 --- Title Processing ---
1- Check if estra title is not set and Operational Mde is default (use nicknames). 
    1.1- If those conditions are met this function fetchs the connection ID of the nickname. 
    1.2- If success when fetching the connection ID this function checks if the connection has a preconfigured title.
    1.3- If an extra title is configured for that specific connection it is used as the terminal_extra_title.
2- Check the first character of the terminal_extra_title string, if it is "-" the function returns only the terminal_extra_title string without the first character,
if not, the function returns the combination of the strings in termianl_extra_title and terminal.
'
    terminal=$1
    Log "Process_title() -- Processing title for terminal $1"
    Log "Process_title() -- Extra_title --> $terminal_extra_title"
    if [[ $terminal_extra_title == "" && $OPER_MODE -eq 0 ]]; then
        Log "Process_title() -- Checking for a configured title for the nickname $terminal"
        connection_id=$(Find_connection_id $terminal)
        if [[ "$connection_id" != "null" ]]; then
            connection_title=$( jq ".connections | .\"$connection_id\" | .title" --raw-output "$path_to_config_file" )
            if [[ "$connection_title" != "null" ]]; then
                Log "Process_title() -- Configured title for $nickname found! --> $connection_title"
                terminal_extra_title="$connection_title"
            else
                Log "Process_title() -- No configured title for $nickname was found"
            fi
        else
            Log "Process_title() -- Configured title not found because nickname $terminal does not have a configured connection"
        fi
    fi
    only_extra=${terminal_extra_title:0:1}
    #terminal_extra_title=$( echo ${terminal_extra_title[@]} | tr -d " ")
    if [[ "$only_extra" = "-" ]]; then
        echo ${terminal_extra_title:1}
    else
        echo "${terminal_extra_title}~$terminal"
    fi
}

Find_terminal(){
    title="$@"
    Log "Find_terminal() -- Finding terminal ---> $title"
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
    Log "Find_terminal() -- Terminal: $title  not found!"
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
: '
 --- Openning Together ---
1- Call function Get_join_title().
2- Call function Process_title().
3- This function must ensure that the title of the terminal to be opnened is unique as it is used to find the uuid:
    3.1- This function loops while the return of the function Find_terminal() is true.
    3.2- If the return of Find_terminal() is true, the counter of terminals with the same title increases by one. Then the title is set to the combination
    of the original title and the counter of terminals with the same title.
    3.3- When the return value of the function Find_terminal() is false, the function exits the loop.
4- Call function Get_connection_command(). 
5- The function opens the terminator terminal that will be the parent of the rest of the terminals.
6- Call function Find_terminal() to find the uuid of the parent terminal that was just openned.
7- Call function Split_terminals() with the uuid of the parent terminal.
'

    join_title="$(Get_join_title)"
    join_title=$(Process_title $join_title)
    title_num=0
    og_join_title=$join_title
    Log "Open_together() -- Checking for duplicated titles . . ." 
    while Find_terminal "$join_title";
    do
        ((title_num++))
        Log "Open_together() -- Duplicated title --> $title_num" 
        join_title="$og_join_title~$title_num"
    done

    first_bash_command=$(Get_connection_command "${terminals_to_open[0]}")
    terminator -p "$terminator_profile" -T "$join_title" -x "$first_bash_command"
    uuid="$(Find_terminal "${join_title[@]}")"
    Log "Open_together() -- Terminal found! uuid --> $uuid"
    Log "Open_together() -- Split pattern switch: pattern selected --> $split_pattern"
    Split_terminals $uuid
}

See_avaiable_machines(){
    if [[ "$available_vms" == "" ]]; then
        echo "No available VMs"
    else
        unknown_machines=false
        i=1
        for entry in "${available_vms[@]}"; do
            vm_name_uuid=($(echo $entry | tr -d "}" | tr "{" " "))
            vm_name=${vm_name_uuid[0]}
            vm_uuid=${vm_name_uuid[1]}
            vm_host_only_mac_addresses=($(vboxmanage showvminfo --details $vm_uuid | grep "Attachment: Host-only Interface" | grep -o 'MAC: [0-9A-F]\{12\}' | cut -d ' ' -f 2))
            vm_bridged_mac_addresses=($(vboxmanage showvminfo --details $vm_uuid | grep "Attachment: Bridged Interface" | grep -o 'MAC: [0-9A-F]\{12\}' | cut -d ' ' -f 2))

            for mac_address in ${vm_host_only_mac_addresses[@]}; do
                vm_ip=($(vboxmanage dhcpserver findlease --interface vboxnet0 --mac-address=$mac_address 2>/dev/null | head -1)) #TODO we only check interface vboxnet0
                if [[ ${vm_ip[2]} != "" ]]; then
                    echo "[$i] $vm_name --> IP: ${vm_ip[2]}"
                    vm_ips+=(${vm_ip[2]})
                    ((i++))
                fi
            done

            for mac_address in ${vm_bridged_mac_addresses[@]}; do
                formatted_mac_address=$(echo $mac_address | sed 's/\(..\)/\1:/g; s/:$//' )
                vm_ip=($(arp -a | grep -i $formatted_mac_address))
                if [[ ${vm_ip[1]} != "" ]]; then
                    formatted_vm_ip=$(echo ${vm_ip[1]} | tr -d "()" )
                    echo "[$i] $vm_name --> IP: $formatted_vm_ip"
                    vm_ips+=($formatted_vm_ip)
                    ((i++))
                else
                    unknown_machines=true
                    if $show_all; then
                        echo "[-] $vm_name --> IP: ??? // mac: $formatted_mac_address"
                    fi
                fi
            done
        done
        if $unknown_machines ; then
            brute_find_ips=false
            read -p "Warning: Unknown machines in the system, use brute force to find IPs? (y/N): " brute_find_ips 
            if [[ "$brute_find_ips" == "y" ]]; then
                for i in {1..254}; do ping -c 1 -W 1 $autocomplete_ip$i & done; wait
            fi
        fi
    fi
}

Get_available_vms(){
    available_vms=($(vboxmanage list runningvms | tr -d " "))
}

Test(){

    sleep 3
    echo "Test done"
}

show_nicknames(){
    jq ".nicknames" "$path_to_config_file" 
    jq ".connections" "$path_to_config_file" 
}

#Argument processing
while [[ $# -gt 0 ]]; do
    case $1 in
        -k | --nickname)
            show_nicknames
            exit 0
            ;;
        --test)
            echo "Testing . . ."
            Test 
            exit 0
            ;;
        -h|--help)
            Help
            exit 0
            shift
            ;;
        --see)
            Get_available_vms
            See_avaiable_machines
            exit 0
            shift
            ;;
        --see-all)
            show_all=true
            Get_available_vms
            See_avaiable_machines
            exit 0
            shift
            ;;
        -c|--show-config)
            jq "." "$path_to_config_file" 
            exit 0
            shift
            ;;
        -v|--verbose)
            Log "Args() -- Setting verbose to true"
            verbose=true #Shows logs
            shift
            ;;
        --no-auth)
            Log "Args() -- Setting auto authenticate to false"
            auto_authenticate=false
            shift
            ;;
        -s | --separated)
            Log "Args() -- Setting join_open to False"
            join_open=false
            ;;
        -j|--join)
            Log "Args() -- Setting join_open to True"
            join_open=true
            shift # past join option
            ;;
        -jv|--joinv)
            Log "Args() -- Setting join_pattern to vertical"
            join_open=true
            split_pattern="vertical"
            shift # past join option
            ;;
        -jh|--joinh)
            Log "Args() -- Setting join_pattern to horizontal"
            join_open=true
            split_pattern="horizontal"
            shift # past join option
            ;;
        -jg|--joing)
            Log "Args() -- Setting join_pattern to grid"
            join_open=true
            split_pattern="grid"
            shift # past join option
            ;;
        -a|--autocomplete)
            Log "Args() -- Warning: default mode disabled, ips will be autocompleted with the configured params"
            OPER_MODE=1
            shift # past not done yet
            ;;
        -d|--default)
            Log "Args() -- Warning: default mode enabled, ot will use the configured nicknames for the connections"
            OPER_MODE=0
            shift # past not done yet
            ;;
        --full-ip)
            Log "Args() -- Warning: Operational mode set to 2 manually - Might as well just use ssh for this"
            OPER_MODE=2
            shift # past not done yet
            ;;
        -w)
            Log "WIRESHARK MODE -- TEST "
            WIRESHARK_MODE=true
            shift
            ;;
        -t|--title)
            Log "Args() -- Switching extra title from [ $terminal_extra_title ] to [ $2 ]"
            terminal_extra_title=$( echo "$2" | tr -d " " )
            shift 2
            ;;
        -n)
            number_to_add=$2
            if [[ $number_to_add -gt $terminal_limit ]]; then
                Log "Args() -- Warning: tried to add $number_to_add terminals. This exceeds the limit of $terminal_limit so that number of terminals will be added instead."
                Log "Args() -- This is a security measure and can be configured in the configuration file, it is recomended to keep the max ammount low to prevent errors."
                number_to_add=$terminal_limit  #Max number to add should probably be a configurable parameter(it now is)

            fi
            Log "Args() -- Adding --> $3 X $number_to_add" 
            for i in $(seq $number_to_add)
            do
                terminals_to_open+=("$3")
            done
            shift 3
            ;;
        -*|--*)
            Log "Args() -- Error: Unknown option $1"
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            Log "Args() -- Adding ot --> $1"
            terminals_to_open+=("$1") # save terminal number/nickname
            shift 
            ;;
    esac
done

if $WIRESHARK_MODE; then
    Log "--- $USER ---"
    for terminal in ${terminals_to_open[@]}
    do
        command_to_execute=$(Get_connection_command "$terminal")
        terminator -x "sudo $command_to_execute"
        #eval $command_to_execute
    done
    exit 0;
fi

if [[ ${#terminals_to_open[@]} -eq 0 ]]; then 
    echo "Select a terminal from your system:"
    Get_available_vms

    if [[ "$available_vms" == "" ]]; then
        echo "No available VMs"
        exit 0
    fi

    See_avaiable_machines
    read -p "--> " selected_vm
    ((selected_vm--))

    OPER_MODE=2     #Operational mode is forced to 2 (full IP/see & select) if no terminals are provided to the ot command
    terminals_to_open+=${vm_ips[$selected_vm]}

    #command_to_execute=$(Get_connection_command "${vm_ips[$selected_vm]}")
    #title=$(Process_title ${vm_ips[$selected_vm]})
    #terminator -T "$title" -p "$terminator_profile" -x "$command_to_execute"
    #exit 0
fi

if $join_open; then
    Log "Opening together:" 
    Log "${terminals_to_open[@]}" 
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



