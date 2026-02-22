# bash hook script
# Copyright (C) 2021-2025 shmilee

## from deb postinst
EasyConnectDir=${VPN_DIR:-/usr/share/sangfor/EasyConnect}
ResourcesDir=${EasyConnectDir}/resources
export EasyConnectDir ResourcesDir

source "${EasyConnectDir}/hook_common.sh"

change_authority() {
    rm -f ${ResourcesDir}/authority_ok
    #文件权限处理
    if [ -f ${EasyConnectDir}/EasyConnect ]; then
        chmod +x ${EasyConnectDir}/EasyConnect
    fi
    #保证logs文件夹存在
    mkdir -p ${ResourcesDir}/logs
    chmod 777 ${ResourcesDir}/logs
    ###CSClient创建的域套接字的句柄在这, 加写权限
    chmod 777 ${ResourcesDir}/conf -R
    chmod +x ${ResourcesDir}/shell/*
    #更改所有者
    chown root:root ${ResourcesDir}/bin/ECAgent
    chown root:root ${ResourcesDir}/bin/svpnservice
    chown root:root ${ResourcesDir}/bin/CSClient
    #添加s权限
    chmod +s ${ResourcesDir}/bin/ECAgent
    chmod +s ${ResourcesDir}/bin/svpnservice
    chmod +s ${ResourcesDir}/bin/CSClient
    #权限ok
    echo -n > ${ResourcesDir}/authority_ok
}

check_EasyConnectDir() {
    if [ ! -d ${ResourcesDir} ]; then
        echo ">> lost resources in dir ${EasyConnectDir}!"
        exit 11
    fi
    local cmd
    for cmd in ${EasyConnectDir}/EasyConnect ${ResourcesDir}/bin/{EasyMonitor,ECAgent,svpnservice,CSClient}; do
        if [ ! -f $cmd ]; then
            echo ">> $cmd not found!"
            exit 12
        fi
        if [ ! -x $cmd ]; then
            echo ">> $cmd not executable!"
            rm -f ${ResourcesDir}/authority_ok
        fi
    done
    for cmd in ${ResourcesDir}/bin/{ECAgent,svpnservice,CSClient}; do
        if [ -u $cmd ] && [ -g $cmd ]; then ## from sslservice.sh
            :
        else
            echo ">> $cmd not -u -g"
            rm -f ${ResourcesDir}/authority_ok
        fi
    done
    if [ ! -f ${ResourcesDir}/authority_ok ]; then
        change_authority
    fi
}

## from github.com/Hagb/docker-easyconnect/ start-sangfor.sh
## from https://blog.51cto.com/13226459/2476193
hook_fix763_login() { #{{{
    if [ -f ${EasyConnectDir}/ecversion ]; then
        if [ x"$(<${EasyConnectDir}/ecversion)" != x"7.6.3" ]; then
            return
        fi
    fi
    echo "Run hook_fix763_login"
    if [ ! -f ${ResourcesDir}/logs/ECAgent.log ]; then
        touch ${ResourcesDir}/logs/ECAgent.log
    fi
    (tail -n 0 -f ${ResourcesDir}/logs/ECAgent.log \
        | grep "\\[Register\\]cms client connect failed" -m 1
        echo "Starting CSClient svpnservice ..."
        run_cmd -auto CSClient
        run_cmd -auto svpnservice -h $ResourcesDir/
    ) &
} #}}}

## use EC cmds in resources/bin-orig/ or resources/bin-cli768/
hook_resources_bin() {
    echo "Run hook_resources_bin"
    if [ ! -d "${ResourcesDir}/bin-orig" ]; then
        echo ">> ${ResourcesDir}/bin-orig/ not found!"
        exit 51
    fi
    if [ ! -d "${ResourcesDir}/bin-cli768" ]; then
        echo ">> ${ResourcesDir}/bin-cli768/ not found!"
        exit 52
    fi
    rm -f -v ${ResourcesDir}/bin
    if [ x"$1" = x"cli768" ]; then
        ln -sf -v bin-cli768 ${ResourcesDir}/bin
    else
        ln -sf -v bin-orig ${ResourcesDir}/bin
    fi
}

## run CLI EC cmd easyconn
ALL_OFF="\001\e[1;0m\002"
BOLD="\001\e[1;1m\002"
GREEN="\001${BOLD}\e[1;32m\002"
BLUE="\001${BOLD}\e[1;34m\002"
YELLOW="\001${BOLD}\e[1;33m\002"
RED="\001${BOLD}\e[1;31m\002"
readonly ALL_OFF BOLD GREEN BLUE YELLOW RED
export TZ=Asia/Shanghai
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:history"
export HISTSIZE=300
export HISTFILESIZE=3000
export HISTTIMEFORMAT="%F %T "
export HISTFILE="${EasyConnectDir}/bash_history"
msg() {
    local mesg=$1; shift
    printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}
warning() {
    local mesg=$1; shift
    printf "${YELLOW}==> WARNING:${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}
prompt1() {
    #local interfaces=($(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|eth0\|\)$/d'))
    #local interfaces=$(ifconfig -a | sed -n 's/[ \t].*//;/^\(tun[0-9]*\)$/p')
    #local interface=${1:-tun0}
    local tuninfo interface
    for interface in $(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|eth0\|\)$/d'); do
        local ip=$(ifconfig $interface | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
        if [ -z "$tuninfo" ]; then
            tuninfo="${ALL_OFF}${BOLD}${interface}:${GREEN}${ip}${ALL_OFF}"
        else
            tuninfo="${tuninfo} ${BOLD}${interface}:${GREEN}${ip}${ALL_OFF}"
        fi
    done
    if [ -n "$tuninfo" ]; then
        tuninfo="${BLUE}[${tuninfo}${BLUE}]${ALL_OFF}-"
    fi
    #$(date '+%T %:::z')
    printf "${BLUE}╭─[${GREEN}$(whoami)${BLUE}@${YELLOW}${HOSTNAME}${BLUE}]${ALL_OFF}-${tuninfo}${BLUE}(${ALL_OFF}${BOLD}$(date '+%T')${ALL_OFF}${BLUE})${ALL_OFF}\n"
}
prompt2() {
    local mesg=$1; shift
    printf "${BLUE}╰─[${ALL_OFF}${BOLD}${mesg}${ALL_OFF}${BLUE}]${ALL_OFF} " "$@" >&1
}
start_easyconn() {
    local params="-v"
    [ -n "$ECADDRESS" ] && params+=" -d $ECADDRESS"
    [ -n "$ECUSER" ] && params+=" -u $ECUSER"
    [ -n "$ECPASSWD" ] && params+=" -p $ECPASSWD"

    local CMD=${ResourcesDir}/bin/easyconn
    local cmd='login'
    history -r  # read the history file
    while true; do
        if [[ "$cmd" == 'login' ]]; then
            msg "Run CMD: $CMD login $params"
            $CMD login $params
            warning "Please run 'clear' to hide you password!!!"
        elif [[ "$cmd" == 'logout' ]]; then
            msg "Run CMD: $CMD logout"
            $CMD logout
        elif [[ "$cmd" == 'mylogin' ]]; then
            local old_params="$params"
            prompt1
            read -e -p "$(prompt2 "Enter new params")" params
            if [ -z "$params" ]; then
                params="$old_params"
            fi
            msg "Run CMD: $CMD login $params"
            $CMD login $params
        elif [[ "$cmd" == 'exit' ]]; then
            msg "Run CMD: $CMD logout"
            $CMD logout
            break
        elif [[ "$cmd" != '' ]]; then
            msg "Run: $cmd"
            $cmd
        fi
        history -s $cmd
        prompt1
        read -p "$(prompt2 'Enter login/logout/mylogin/bash/exit/??')" -e cmd
    done
    history -w  # write to the history file
}

## run cmd in ${EasyConnectDir}, like EasyConnect
start_EC() {
    local CMD=${1:-EasyConnect}
    if [ ! -f ${EasyConnectDir}/$CMD ]; then
        echo ">> '$CMD' not found in ${EasyConnectDir}!"
        exit 31
    fi
    local params="${@:2}"
    if [[ "$CMD" == 'EasyConnect' ]] && [ -z "$params" ]; then
        params="--enable-transparent-visuals --disable-gpu"
    fi
    echo "Run CMD: ${EasyConnectDir}/$CMD $params"
    ${EasyConnectDir}/$CMD $params
}

## main
main() {
    echo "Running default EasyConnect main ..."
    if [[ "$UI" == "CLI" ]]; then
        hook_resources_bin cli768
    else
        hook_resources_bin orig
    fi
    check_EasyConnectDir

    [ -n "$IPTABLES" ] && hook_iptables tun0 # IPTABLES_LEGACY=
    [ -n "$NODANTED" ] || hook_danted tun0   # -p xxx:1080
    [ x"$UI" = x"VNC" ] && hook_vnc   # PASSWORD= ECPASSWORD= -p xxx:5901
    [ -n "$SSHD" ] && hook_sshd       # ROOTPASSWD= -p xxxx:22
    hook_fix763_login                 # if EC VERSION is 7.6.3
    # ignore: URLWIN=1, shell/open_browser.sh. Use xdg-open in host.

    run_cmd -auto EasyMonitor

    if [[ "$UI" == "CLI" ]]; then
        start_easyconn
    else
        start_EC
    fi
}
