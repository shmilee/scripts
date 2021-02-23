#!/bin/bash
# $1 wait for volume
# $2 path of hook_script.sh
sleep ${1:-5}

## from deb postinst
EasyConnectDir=/usr/share/sangfor/EasyConnect
ResourcesDir=${EasyConnectDir}/resources

change_authority() {
    rm -f ${ResourcesDir}/authority_ok
    #文件权限处理
    chmod +x ${EasyConnectDir}/EasyConnect
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
    local cmd
    if [ ! -d ${EasyConnectDir} ]; then
        echo ">> ${EasyConnectDir} not found!"
        echo ">> Need to bind mount the volume! (-v)!"
        exit 11
    fi
    if [ ! -d ${ResourcesDir} ]; then
        echo ">> lost resources in dir ${EasyConnectDir}!"
        exit 12
    fi
    for cmd in ${EasyConnectDir}/EasyConnect \
            ${ResourcesDir}/bin/{ECAgent,svpnservice,CSClient}; do
        if [ ! -f $cmd ]; then
            echo ">> $cmd not found!"
            exit 13
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

## rum cmd in ${ResourcesDir}/bin
## from sslservice.sh EasyMonitor.sh
run_cmd() {
    local cmd=$1
    local background=${2:-foreground} # background, foreground
    local params="${@:3}"
    if [ ! -f "${ResourcesDir}/bin/$cmd" ]; then
        echo ">> '$cmd' not found in ${ResourcesDir}/bin!"
        exit 21
    fi
    pidof $cmd >/dev/null && killall $cmd
    pidof $cmd >/dev/null && killall -9 $cmd
    if [ x"$background" == "xbackground" ]; then
        echo "Run CMD: ${ResourcesDir}/bin/$cmd $params &"
        ${ResourcesDir}/bin/$cmd $params &
    else
        echo "Run CMD: ${ResourcesDir}/bin/$cmd $params"
        ${ResourcesDir}/bin/$cmd $params
    fi
    if [ $? -eq 0 ]; then
        echo "Start $cmd success!"
    else
        echo ">> Start $cmd fail"
        exit 22
    fi
}

## exec EasyConnect
start_EC() {
    local ECCMD=${EasyConnectDir}/EasyConnect
    local params="--enable-transparent-visuals --disable-gpu"
    if [ ! -f $ECCMD ]; then
        echo ">> '$ECCMD' not found in ${EasyConnectDir}!"
        exit 31
    fi
    echo "Run CMD: $ECCMD $params"
    $ECCMD $params
}

## main
main() {
    echo "Running default main ..."
    check_EasyConnectDir
    run_cmd EasyMonitor
    start_EC
}

## source hook script, add functions & reload change_authority, main etc.
hook_script="${2:-${EasyConnectDir}/hook_script.sh}"
if [ -f "$hook_script" ]; then
    echo "source hook_script.sh ..."
    source $hook_script
fi

main
