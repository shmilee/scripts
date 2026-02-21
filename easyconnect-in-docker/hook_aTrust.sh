# bash hook script
# Copyright (C) 2026 shmilee

## from aTrust deb postinst
aTrustDir=${aTrustDir:-/usr/share/sangfor/aTrust}
ResourcesDir=${aTrustDir}/resources
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${ResourcesDir}/lib:${ResourcesDir}/bin
QT_QPA_PLATFORM_PLUGIN_PATH=${ResourcesDir}/lib
export aTrustDir ResourcesDir LD_LIBRARY_PATH QT_QPA_PLATFORM_PLUGIN_PATH

source "${aTrustDir}/hook_common.sh"

change_authority() {
  :
}

check_aTrustDir() {
    if [ ! -d ${ResourcesDir} ]; then
        echo ">> lost resources in dir ${aTrustDir}!"
        exit 11
    fi
    local cmd
    for cmd in ${aTrustDir}/aTrustTray ${ResourcesDir}/bin/aTrustAgent; do
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

run_agent() {
    FAKE_LOGIN=sangfor LD_PRELOAD=/usr/local/lib/fake-getlogin.so \
        run_cmd -bg aTrustAgent --plugin plugin-daemon --plugin-cmd \| \
        >/tmp/aTrustAgent.log
}

## main
main() {
    echo "Running default aTrust main ..."
    check_aTrustDir

    [ -n "$IPTABLES" ] && hook_iptables utun7 # IPTABLES_LEGACY=
    [ -n "$NODANTED" ] || hook_danted utun7   # -p xxx:1080
    [ x"$UI" = x"VNC" ] && hook_vnc   # PASSWORD= ECPASSWORD= -p xxx:5901
    [ -n "$SSHD" ] && hook_sshd       # ROOTPASSWD= -p xxxx:22
    # ignore: URLWIN=1, shell/open_browser.sh. Use xdg-open in host.

    run_agent
    ${aTrustDir}/aTrustTray --no-sandbox
}
