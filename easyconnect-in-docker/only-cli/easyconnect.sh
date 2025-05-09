#!/bin/bash
# $1 wait for volume
# $2 path of hook_script.sh
sleep ${1:-5}

## from deb postinst
EasyConnectDir=${EasyConnectDir:-/usr/share/sangfor/EasyConnect}
ResourcesDir=${EasyConnectDir}/resources

## run cmd in ${ResourcesDir}/bin
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
    if [ x"$background" = "xbackground" ]; then
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
        if [ "$cmd" = 'login' ]; then
            msg "Run CMD: $CMD login $params"
            $CMD login $params
            warning "Please run 'clear' to hide you password!!!"
        elif [ "$cmd" = 'logout' ]; then
            msg "Run CMD: $CMD logout"
            $CMD logout
        elif [ "$cmd" = 'mylogin' ]; then
            local old_params="$params"
            prompt1
            read -e -p "$(prompt2 "Enter new params")" params
            if [ -z "$params" ]; then
                params="$old_params"
            fi
            msg "Run CMD: $CMD login $params"
            $CMD login $params
        elif [ "$cmd" = 'exit' ]; then
            msg "Run CMD: $CMD logout"
            $CMD logout
            break
        elif [ "$cmd" != '' ]; then
            msg "Run: $cmd"
            $cmd
        fi
        history -s $cmd
        prompt1
        read -p "$(prompt2 'Enter login/logout/mylogin/bash/exit/??')" -e cmd
    done
    history -w  # write to the history file
}

## from github.com/Hagb/docker-easyconnect/ start.sh
hook_iptables() { #{{{
    local interface=${1:-tun0}
    echo "Run hook_iptables"
    # 不支持 nftables 时使用 iptables-legacy
    # 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
    if { [ -z "$IPTABLES_LEGACY" ] && iptables-nft -L 1>/dev/null 2>/dev/null ;}
    then
        update-alternatives --set iptables /usr/sbin/iptables-nft
        update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
    else
        update-alternatives --set iptables /usr/sbin/iptables-legacy
        update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
    fi

    # https://github.com/Hagb/docker-easyconnect/issues/20
    # https://serverfault.com/questions/302936/configuring-route-to-use-the-same-interface-for-outbound-traffic-as-that-of-inbo
    iptables -t mangle -I OUTPUT -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark
    iptables -t mangle -I PREROUTING -m connmark ! --mark 0 -j CONNMARK --save-mark
    iptables -t mangle -I PREROUTING -m connmark --mark 1 -j MARK --set-mark 1
    iptables -t mangle -I PREROUTING -i eth0 -j CONNMARK --set-mark 1
    (
    IFS=$'\n'
    for i in $(ip route show); do
        IFS=' '
        ip route add $i table 2
    done
    ip rule add fwmark 1 table 2
    )

    iptables -t nat -A POSTROUTING -o ${interface} -j MASQUERADE

    # 拒绝 interface tun0 侧主动请求的连接.
    iptables -I INPUT -p tcp -j REJECT
    iptables -I INPUT -i eth0 -p tcp -j ACCEPT
    iptables -I INPUT -i lo -p tcp -j ACCEPT
    iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # 删除深信服可能生成的一条 iptables 规则，防止其丢弃传出到宿主机的连接
    # 感谢 @stingshen https://github.com/Hagb/docker-easyconnect/issues/6
    ( while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP 2>/dev/null ; done ) &
} #}}}

## from github.com/Hagb/docker-easyconnect/ start.sh
hook_danted() { #{{{
    local interface=${1:-tun0}
    echo "Run hook_danted"
    cat >/etc/danted.conf <<EOF
internal: eth0 port = 1080
external: ${interface}
external: eth0
external: lo
external.rotation: route
socksmethod: none
clientmethod: none
user.privileged: proxy
user.notprivileged: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF
    pidof danted >/dev/null && killall danted
    pidof danted >/dev/null && killall -9 danted
    (while true; do
        sleep 3
        if [ -d /sys/class/net/${interface} ]; then
            danted -D -f /etc/danted.conf
            break
        fi
    done) &
} #}}}

## use conf in resources/conf-v$VERSION
hook_resources_conf() {
    if [ x"$VERSION" = x"7.6.3" ] || [ x"$VERSION" = x"7.6.7" ] || [ x"$VERSION" = x"7.6.8" ]; then
        :
    else
        echo ">> Not supported EC version: $VERSION"
        exit 51
    fi
    echo "Run hook_resources_conf"
    if [ ! -d "${ResourcesDir}/conf-v$VERSION" ]; then
        echo ">> ${ResourcesDir}/conf-v$VERSION/ not found!"
        exit 52
    fi
    rm -f -v ${ResourcesDir}/conf
    ln -sf -v conf-v$VERSION ${ResourcesDir}/conf
    if [ -f /root/.easyconn ]; then
        ln -sf -v /root/.easyconn ${ResourcesDir}/conf/.easyconn
    fi
}

## main
main() {
    echo "Running default main ..."
    hook_resources_conf

    [ -n "$IPTABLES" ] && hook_iptables tun0 # IPTABLES_LEGACY=
    [ -n "$NODANTED" ] || hook_danted tun0   # -p xxx:1080

    run_cmd ECAgent background --resume
    start_easyconn
}

## source hook script, add functions & reload change_authority, main etc.
hook_script="${2:-${EasyConnectDir}/hook_script.sh}"
if [ -f "$hook_script" ]; then
    echo "source hook_script.sh ..."
    source $hook_script
fi

main
