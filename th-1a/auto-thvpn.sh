#!/usr/bin/env bash
depends=('icedtea-web' 'iproute2' 'sed' 'firefox')

down_file='sslvpn_jnlp.cgi' #change SvpnUid, get by firefox
mode=3 # 1 2 3
_IF=eth0 # valid for mode 2 3

myip=$(ip addr show $_IF |sed -n 's/^[ \t].*inet \(.*\)\/.*brd.*$/\1/p')
if [[ m$mode == m1 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', x=1,2,3,8,9
    ## port 2222
    sed 's/local=TH-1A-LN[12389]:22/&22/g' $down_file >tmp_vpn.jnlp
elif [[ m$mode == m2 ]]; then
    ## local --> '127.0.0.xx TH-1A-LNx', except '$myip:222j TH-1A-LNj', j=3,9
    ## port 2222 2223 2229
    sed -e 's/local=TH-1A-LN[128]:22/&22/g' \
        -e "s/local=TH-1A-LN\([39]\):22/local=$myip:222\1/g" \
        $down_file >tmp_vpn.jnlp
elif [[ m$mode == m3 ]]; then
    ## local --> '$myip:222x TH-1A-LNx'
    ## port 2221 2222 2223 2228 2229
    sed -e "s/local=TH-1A-LN\([12389]\):22/local=$myip:222\1/g" $down_file >tmp_vpn.jnlp
else
    echo 'Null mode.'
    exit 0
fi

## Run
javaws tmp_vpn.jnlp
rm tmp_vpn.jnlp
