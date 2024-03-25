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
start_easyconn() {
    local params="-v"
    [ -n "$ECADDRESS" ] && params+=" -d $ECADDRESS"
    [ -n "$ECUSER" ] && params+=" -u $ECUSER"
    [ -n "$ECPASSWD" ] && params+=" -p $ECPASSWD"

    local CMD=${ResourcesDir}/bin/easyconn
    local cmd='login'
    while true; do
        if [ "$cmd" = 'login' ]; then
            echo "Run CMD: $CMD login $params"
            $CMD login $params
        elif [ "$cmd" = 'logout' ]; then
            echo "Run CMD: $CMD logout"
            $CMD logout
        elif [ "$cmd" = 'mylogin' ]; then
            read -p " -> Enter new params: " params
            echo "Run CMD: $CMD login $params"
            $CMD login $params
        elif [ "$cmd" = 'exit' ]; then
            echo "Run CMD: $CMD logout"
            $CMD logout
            break
        elif [ "$cmd" != '' ]; then
            echo " => Run: $cmd"
            $cmd
        fi
        read -p " -> Enter 'login/logout/mylogin/??/exit': " cmd
    done
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
