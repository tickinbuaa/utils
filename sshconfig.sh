DB_LOGIN_PATH="localdb-sshconfig"
function get_ssh_config(){
    if [ $# -ne 2 ]; then
        echo "Usage: get_ssh_config ssh-config-name field-name"
        return 1
    fi  
    ssh_config=$1
    field_name=$2
    echo `runsql "select $field_name from sshconfig.sshserver where name = \"$config_name\";"` 
}

function assign(){
    if [ $# -ne 2 ]; then
        echo "Usage: assign value default-value"
        return 1
    fi  
    if [ "$1" != "" ]; then
        echo $1
    else
        echo $2
    fi  
}

function runsql(){
    info=`mysql --login-path=$DB_LOGIN_PATH --skip-column-names -e "$*"`
    echo "$info"
    echo "$?"
    return $?
}

function sshconfig(){
    (
        set -e
        echo -n "SSH Config Name:"
        read config_name
        `runsql "create database if not exists sshconfig;"`
        `runsql "use sshconfig;create table if not exists sshserver(name varchar(64) primary key, port int not null, host varchar(32) not null, ipath varchar(128) not null, user varchar(64) not null);"` 
        user=`get_ssh_config $config_name user`
        host=`get_ssh_config $config_name host`
        port=`get_ssh_config $config_name port`
        ipath=`get_ssh_config $config_name ipath`
        if [ "$user" = "" ]; then
            no_result="true"
        fi
        echo -n "User[default:$user]:"
        read user_input
        user=`assign "$user_input" "$user"`
        echo -n "Host[default:$host]:"
        read user_input
        host=`assign "$user_input" "$host"`
        echo -n "Port[default:$port]:"
        read user_input
        port=`assign "$user_input" "$port"`
        echo -n "Identity File Path[default:$ipath]:"
        read user_input
        ipath=`assign "$user_input" "$ipath"`
        if [ "$no_result" != "true" ]; then
            `runsql "update sshconfig.sshserver set user=\"$user\", host=\"$host\", port=\"$port\", ipath=\"$ipath\" where name=\"$config_name\";"`
        else
            `runsql "insert into sshconfig.sshserver(name, user, host, port, ipath) values(\"$config_name\",\"$user\", \"$host\", \"$port\", \"$ipath\");"`
        fi
    )
}

function sshto(){
    if [ $# -ne 1 ]; then
        echo "Usage sshto ssh config-name"
        return 1
    fi
    #set -e
    config_name=$1
    user=`get_ssh_config $config_name user`
    if [ "$user" = "" ]; then
        echo "No ssh config named $config_name exists in DB, please configure first"
        return 1
    fi
    host=`get_ssh_config $config_name host`
    port=`get_ssh_config $config_name port`
    ipath=`get_ssh_config $config_name ipath`
    echo "Will ssh to ssh server(host:$host, port:$port) as user $user with identity file $ipath"
    ssh -i "$ipath" -p "$port" "$user"@"$host"
}

function scpto(){
    if [ $# -ne 3 ] && [ $# -ne 2 ]; then
        echo "Usage scpto ssh-config-name source-file-path [target-file-dir]"
        return -1
    fi
    config_name=$1
    source_file_path=$2
    if [ $# = 2 ]; then
        target_file_path=$2
    else
        target_file_path=$3
    fi
    if [[ "$3" != /* ]]; then
        target_file_path="~/$target_file_path"
    fi
    user=`get_ssh_config $config_name user`
    if [ "$user" = "" ]; then
        echo "No ssh config named $config_name exists in DB, please configure first"
        return 1
    fi
    host=`get_ssh_config $config_name host`
    port=`get_ssh_config $config_name port`
    ipath=`get_ssh_config $config_name ipath`
    scp -i "$ipath" -P "$port" "$source_file_path" "$user"@"$host":"$target_file_path"
}

function scpfrom(){
    if [ $# -ne 3 ]; then
        echo "Usage scpfrom ssh-config-name source-file-path target-file-dir"
        return -1
    fi
    config_name=$1
    source_file_path=$2
    target_file_dir=$3
    user=`get_ssh_config $config_name user`
    if [ "$user" = "" ]; then
        echo "No ssh config named $config_name exists in DB, please configure first"
        return 1
    fi
    host=`get_ssh_config $config_name host`
    port=`get_ssh_config $config_name port`
    ipath=`get_ssh_config $config_name ipath`
    scp -i "$ipath" -P "$port" "$user"@"$host":"$source_file_path" "$target_file_dir"
}
