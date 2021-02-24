# bash hook script
# Copyright (C) 2021 shmilee

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
        update-alternatives --set ip6tables /usr/sbin/ip6tables-le    gacy
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

## from github.com/Hagb/docker-easyconnect/ start.sh
hook_vnc() { #{{{
    echo "Run hook_vnc"
    apt-get update
    apt-get install -y --no-install-recommends --no-install-suggests \
        xclip tigervnc-standalone-server tigervnc-common flwm x11-utils
    # container 再次运行时清除 /tmp 中的锁，使 container 能够反复使用。
    # 感谢 @skychan https://github.com/Hagb/docker-easyconnect/issues/4#issuecomment-660842149
    rm -rf /tmp
    mkdir /tmp

    # $PASSWORD 不为空时，更新 vnc 密码
    [ -e ~/.vnc/passwd ] || (mkdir -p ~/.vnc && (echo password | tigervncpasswd -f > ~/.vnc/passwd)) 
    [ -n "$PASSWORD" ] && printf %s "$PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd

    tigervncserver :1 -geometry 800x600 -localhost no -passwd ~/.vnc/passwd -xstartup flwm
    DISPLAY=:1

    # 将 easyconnect 的密码放入粘贴板中，应对密码复杂且无法保存的情况 (eg: 需要短信验证登陆)
    # 感谢 @yakumioto https://github.com/Hagb/docker-easyconnect/pull/8
    echo "$ECPASSWORD" | DISPLAY=:1 xclip -selection c
} #}}}

## use sshd instead of danted
hook_sshd() {
    echo "Run hook_sshd"
    if [ ! -d /run/sshd ]; then
        mkdir -pv /run/sshd
    fi
    passwd="${ROOTPASSWD:-1234567890}"
    echo "root:$passwd" | chpasswd
    sed -i 's|#PermitRootLogin.*$|PermitRootLogin yes|' /etc/ssh/sshd_config
    /usr/sbin/sshd -f /etc/ssh/sshd_config
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
        run_cmd CSClient
        run_cmd svpnservice foreground -h $ResourcesDir/
    ) &
} #}}}

## reload main
main() {
    echo "Running hook main ..."
    check_EasyConnectDir

    [ -n "$IPTABLES" ] && hook_iptables tun0 # IPTABLES_LEGACY=
    [ -n "$NODANTED" ] || hook_danted tun0   # -p xxx:1080
    [ x"$TYPE" = x"VNC" ] && hook_vnc # PASSWORD= ECPASSWORD= -p xxx:5901
    [ -n "$SSHD" ] && hook_sshd       # ROOTPASSWD= -p xxxx:22
    hook_fix763_login                 # if EC VERSION is 7.6.3
    # ignore: -e URLWIN=1, $ResourcesDir/shell/open_browser.sh

    run_cmd EasyMonitor
    start_EC
}

