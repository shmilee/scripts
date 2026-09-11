# bash hook script
# Copyright (C) 2026 shmilee

## from TopSAP deb postinst
TopSAPDir=${TopSAPDir:-/opt/TopSAP}
# ele/ holds libffmpeg.so (GUI) ; lib/ holds bundled GTK3/webkit libs
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${TopSAPDir}:${TopSAPDir}/lib:${TopSAPDir}/ele
export TopSAPDir LD_LIBRARY_PATH

source "${TopSAPDir}/hook_common.sh"

change_authority() {
    mkdir -p /opt/sslvpn/config
    touch /opt/sslvpn/config/vpnclient-sysconfig
    touch /opt/sslvpn/config/resinfo-config
    touch /opt/sslvpn/config/spa_dateconfig
    touch /opt/sslvpn/config/spaconfig
    touch /opt/sslvpn/config/.sysconfig
    chmod -R 777 /opt/sslvpn
    chmod -R 777 /opt/TopSAP
    chown root /opt/TopSAP/ele/chrome-sandbox
    chmod 4755 /opt/TopSAP/ele/chrome-sandbox
}

check_TopSAPDir() {
    if [ ! -d ${TopSAPDir}/ele ]; then
        echo ">> lost ${TopSAPDir}/ele!"
        exit 11
    fi
    local cmd
    for cmd in ${TopSAPDir}/ele/TopSAP ${TopSAPDir}/sv_websrv; do
        if [ ! -f $cmd ]; then
            echo ">> $cmd not found!"
            exit 12
        fi
        if [ ! -x $cmd ]; then
            echo ">> $cmd not executable!"
            chmod +x $cmd
        fi
    done
}

## sv_websrv is the core VPN service (serves the login API on 127.0.0.1:7443,
## creates tun0 after login). The official flow (TopVPNhelper) runs the
## TOP-LEVEL ${TopSAPDir}/sv_websrv from cwd=${TopSAPDir}; it dlopen()s
## ./libtopsec_vpn.so (cwd-relative) and shares /tmp/TopSAP_ELE/.BUFF with the
## GUI. Launch it from ${TopSAPDir}, not ele/.
start_sv_websrv() {
    ( cd ${TopSAPDir} && \
      FAKE_LOGIN=sangfor LD_PRELOAD=/usr/local/lib/fake-getlogin.so \
      exec ./sv_websrv ) >/tmp/sv_websrv.log 2>&1 &
    echo "sv_websrv started (pid $!), log: /tmp/sv_websrv.log"
}

run_agent() {
    start_sv_websrv
}

## replace the old cron/sv_sever.sh keep-alive: restart sv_websrv if it dies
keep_agent() {
    ( while true; do
        sleep 5
        if ! pidof sv_websrv >/dev/null 2>&1; then
            echo ">> sv_websrv not running, restarting ..."
            start_sv_websrv
        fi
    done ) &
}

## wait for tun0 (created by sv_websrv after login), then set MTU + MASQUERADE
hook_tun0() {
    ( while true; do
        sleep 1
        if [ -d /sys/class/net/tun0 ]; then
            ip link set dev tun0 mtu 1300
            iptables -t nat -C POSTROUTING -o tun0 -j MASQUERADE 2>/dev/null || \
                iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
            echo ">> tun0 ready (mtu 1300, MASQUERADE set)"
            break
        fi
    done ) &
}

## main
main() {
    echo "Running default TopSAP main ..."
    check_TopSAPDir
    change_authority

    [ -n "$IPTABLES" ] && hook_iptables tun0 # IPTABLES_LEGACY= (full routing)
    [ -n "$NODANTED" ] || hook_danted tun0   # -p xxx:1080 (socks5)
    [ x"$UI" = x"VNC" ] && hook_vnc   # PASSWORD= -p xxx:5901
    [ -n "$SSHD" ] && hook_sshd       # ROOTPASSWD= -p xxxx:22

    run_agent
    keep_agent
    hook_tun0

    # --no-sandbox: container runs as root, setuid sandbox is unavailable.
    # --disable-gpu / --disable-dev-shm-usage: no GPU in docker and /dev/shm is
    # small; avoids intermittent gpu-process init crashes (SIGTRAP).
    ${TopSAPDir}/ele/TopSAP --no-sandbox --disable-gpu --disable-dev-shm-usage
}
