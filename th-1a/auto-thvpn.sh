#!/usr/bin/env bash
depends=('icedtea-web' 'iproute2' 'sed' 'firefox')

down_file='sslvpn_jnlp.cgi' #change SvpnUid, get by firefox
mode=2 # 1 2
_IF=eth0 # valid for mode 2

if [[ m$mode == m1 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', x=1,2,3,8,9
    ## port 2222
    sed 's/local=TH-1A-LN[12389]:22/&22/g' $down_file >tmp_vpn.jnlp
elif [[ m$mode == m2 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', except '$myip TH-1A-LN3'
    ## port 2222
    myip=$(ip addr show $_IF |sed -n 's/^[ \t].*inet \(.*\)\/.*brd.*$/\1/p')
    sed -e 's/local=TH-1A-LN[1289]:22/&22/g' -e "s/local=TH-1A-LN3:22/local=$myip:2222/" $down_file >tmp_vpn.jnlp
else
    echo 'Null mode.'
    exit 0
fi

## Run
javaws tmp_vpn.jnlp
rm tmp_vpn.jnlp
