#!/usr/bin/env bash
depends=('icedtea-web' 'iproute2' 'sed' 'firefox' 'curl')

down_file='sslvpn_jnlp.cgi' #change SvpnUid, get by firefox
mode=3 # 1 2 3
_IF=eth0 # valid for mode 2 3

RET=1
if [ x$1 == x-d -o x$1 == xd ];then
    #download_jars
    jars=$(sed -n '/href.*jar/ s/^.*="\(.*\)".*$/\1/ p' sslvpn_jnlp.cgi)
    codebase=$(sed -n '/codebase="/ s/^.*codebase="\(.*\)".*$/\1/ p' sslvpn_jnlp.cgi)
    [ -d ./sslvpn ] && rm -r ./sslvpn/
    mkdir -pv ./sslvpn/{linux,mac,windows}
    RET=0
    for jar in $jars; do
        curl -fLC - --retry 3 --retry-delay 3 -k -o ./sslvpn/$jar "$codebase$jar" || RET=1
    done
    [[ $RET == 1 ]] && rm -r ./sslvpn/
fi
if [ $RET == 0 -o -d ./sslvpn ]; then
    echo 'Use local codebase.'
    sed 's|\(^.*codebase="\).*\(".*$\)|\1file:./sslvpn/\2|' $down_file >tmp_vpn.jnlp
else
    echo 'No download_jars.'
    cat $down_file >tmp_vpn.jnlp
fi

myip=$(ip addr show $_IF |sed -n 's/^[ \t].*inet \(.*\)\/.*brd.*$/\1/p')
if [[ m$mode == m1 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', x=1,2,3,8,9
    ## port 2222
    sed -i 's/local=TH-1A-LN[12389]:22/&22/g' tmp_vpn.jnlp
elif [[ m$mode == m2 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', except '$myip:222j TH-1A-LNj', j=3,9
    ## port 2222 2223 2229
    sed -i -e 's/local=TH-1A-LN[128]:22/&22/g' \
        -e "s/local=TH-1A-LN\([39]\):22/local=$myip:222\1/g" tmp_vpn.jnlp
elif [[ m$mode == m3 ]]; then
    ## local --> '$myip:222x TH-1A-LNx'
    ## port 2221 2222 2223 2228 2229
    sed -i -e "s/local=TH-1A-LN\([12389]\):22/local=$myip:222\1/g" tmp_vpn.jnlp
else
    echo 'Null mode.'
    exit 0
fi

## Run
javaws tmp_vpn.jnlp
rm tmp_vpn.jnlp
