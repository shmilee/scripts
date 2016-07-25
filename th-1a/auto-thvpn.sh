#!/usr/bin/env bash
depend_pkgs=('icedtea-web' 'iproute2' 'sed' 'firefox' 'curl')
depend_file='sslvpn_jnlp.cgi' #change SvpnUid, get by firefox

usage() {
    cat <<EOF
$0 -f /path/to/sslvpn_jnlp.cgi [-d] [-i] [-m]

  -h        show this help
  -p        print mode info
  -d        download jars of ssl vpn
  -f < >    set config file
  -i < >    set a network interface before
            the default list 'eth0 wlan0 lo'
            useful for mode 2
  -m [1|2]  set mode number
EOF
}

mode_info() {
    cat <<EOF
# mode 1 (default)

TH-1A-LN1:22 -> TH-1A-LN1:2222
TH-1A-LN2:22 -> TH-1A-LN2:2222
TH-1A-LN3:22 -> TH-1A-LN3:2222
TH-1A-LN8:22 -> TH-1A-LN8:2222
TH-1A-LN9:22 -> TH-1A-LN9:2222
TH-1A-ns1:22 -> TH-1A-ns1:2222

##H3C8042HJJMTW ADD
127.0.0.2 TH-1A-LN1
127.0.0.3 TH-1A-LN2
127.0.0.4 TH-1A-LN3
127.0.0.5 TH-1A-LN8
127.0.0.6 TH-1A-LN9
127.0.0.7 TH-1A-ns1

# mode 2

network interface IP: netIP
TH-1A-LN1:22 -> netIP:2221
TH-1A-LN2:22 -> netIP:2222
TH-1A-LN3:22 -> netIP:2223
TH-1A-LN8:22 -> netIP:2228
TH-1A-LN9:22 -> netIP:2229
TH-1A-ns1:22 -> netIP:2231

IF_list=(eth0 wlan0 lo)

EOF
}

while getopts 'df:i:m:hp' arg; do
    case "$arg" in
        d) _download='yes';;
        f) _config_file="$OPTARG" ;;
        i) _IF="$OPTARG" ;;
        m) _mode="$OPTARG" ;;
        p) mode_info; exit 0 ;;
        h|*) usage; exit 0 ;;
	esac
done

RUNPATH=/tmp/sslvpn4th1a

if [ ! -d $RUNPATH ]; then
    mkdir -pv $RUNPATH
    _download='yes'
fi

_config_file=${_config_file:-./sslvpn_jnlp.cgi}
if [ ! -f $_config_file ]; then
    echo "!!! lost jnlp file(sslvpn_jnlp.cgi): $_config_file, get by firefox."
    usage
    exit 1
fi
cp $_config_file $RUNPATH/sslvpn.jnlp

_mode=${_mode:-1}

IF_list=(eth0 wlan0 lo)
for netif in $_IF ${IF_list[@]}; do
    if [[ x$_mode == 'x1' ]]; then
        break
    fi
    if [ -f /sys/class/net/$netif/operstate ]; then
        if [[ $(cat /sys/class/net/$netif/operstate) == 'up' ]]; then
            _myIP=$(ip addr show $netif | sed -n 's/^[ \t].*inet \(.*\)\/.*brd.*$/\1/p')
            echo "Using network interface: $netif ($_myIP)"
            break
        fi
    fi
done

_RET=1
if [ x$_download == 'xyes' ]; then
    #download jars
    jars=$(sed -n '/href.*jar/ s/^.*="\(.*\)".*$/\1/ p' $RUNPATH/sslvpn.jnlp)
    codebase=$(sed -n '/codebase="/ s/^.*codebase="\(.*\)".*$/\1/ p' $RUNPATH/sslvpn.jnlp)
    [ -d $RUNPATH/sslvpn ] && rm -r $RUNPATH/sslvpn/
    mkdir -pv $RUNPATH/sslvpn/{linux,mac,windows}
    _RET=0
    for jar in $jars; do
        curl -fLC - --retry 3 --retry-delay 3 -k -o $RUNPATH/sslvpn/$jar "$codebase$jar" || _RET=1
    done
    if [[ $_RET == 1 ]]; then
        rm -r $RUNPATH/sslvpn/
    fi
fi
if [ $_RET == 0 -o -d $RUNPATH/sslvpn ]; then
    echo 'Use local codebase.'
    sed -i 's|\(^.*codebase="\).*\(".*$\)|\1file:./sslvpn/\2|' $RUNPATH/sslvpn.jnlp
else
    echo 'Warnning: No download sslvpn jars.'
fi

if [[ x$_mode == 'x1' ]]; then
    sed -i -e 's/local=TH-1A-LN[12389]:22/&22/g' \
           -e 's/local=TH-1A-ns1:22/&22/g' $RUNPATH/sslvpn.jnlp
elif [[ x$_mode == 'x2' ]]; then
    sed -i -e "s/local=TH-1A-LN\([12389]\):22/local=$_myIP:222\1/g" \
           -e "s/local=TH-1A-ns1:22/local=$_myIP:2231/g" $RUNPATH/sslvpn.jnlp
else
    echo '!!! Illegal mode.'
    usage
    exit 3
fi

## Run
cd $RUNPATH/
javaws sslvpn.jnlp
