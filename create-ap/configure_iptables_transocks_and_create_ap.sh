#!/usr/bin/bash

# Transocks: https://github.com/cybozu-go/transocks
# 1. Install: go get -u github.com/cybozu-go/transocks/...
# Note: depending on your vension of go, you will need the env: GO111MODULE=on
# 2. Create a "transocks" user
# 3. Execute: sudo -u transocks $HOME/go/bin/transocks -f transocks.toml

set -e
stty -echoctl

# Point to the transparent socket port (running in an exclusive user)
TRANSOCKS_PORT=12345
TRANSOCKS_USER=$USER

# Redirect all the network of your computer (except transocks user)
REDIRECT_LOCAL_NETWORK=0

# Redirect access point (wifi hotspot)
AP_SUBNET_ENABLED=1
AP_SUBNET_IFACE=ap0
AP_SUBNET_RANGE="192.168.6.0/24"

function action_up()
{
    echo "-----------------------------"
    echo "# Adding iptables chain rules"
    echo "-----------------------------"
    iptables -v -t nat -N TRANSOCKS
    iptables -v -t nat -A TRANSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 100.64.0.0/10 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 198.18.0.0/15 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -v -t nat -A TRANSOCKS -d 240.0.0.0/4 -j RETURN
    iptables -v -t nat -A TRANSOCKS -p tcp -j REDIRECT --to-ports $TRANSOCKS_PORT

    if [ "$REDIRECT_LOCAL_NETWORK" = 1 ]; then
        echo "--------------------------------"
        echo "# Redirecting non-transocks user"
        echo "--------------------------------"
        iptables -v -t nat -A OUTPUT -p tcp -m owner ! --uid-owner $TRANSOCKS_USER -j TRANSOCKS
    fi

    if [ "$AP_SUBNET_ENABLED" = 1 ]; then
        echo "-----------------------"
        echo "# Redirecting AP subnet"
        echo "-----------------------"
        iptables -v -t nat -I PREROUTING -i $AP_SUBNET_IFACE -s $AP_SUBNET_RANGE -j TRANSOCKS
        iptables -v -I INPUT -i $AP_SUBNET_IFACE -s $AP_SUBNET_RANGE -p tcp -m tcp --dport $TRANSOCKS_PORT -j ACCEPT
    fi
}

function action_down()
{
    if [ "$REDIRECT_LOCAL_NETWORK" = 1 ]; then
        echo "------------------------------"
        echo "# Cleaning non-transocks rules"
        echo "------------------------------"
        iptables -v -t nat -D OUTPUT -p tcp -m owner ! --uid-owner $TRANSOCKS_USER -j TRANSOCKS
    fi

    if [ "$AP_SUBNET_ENABLED" = 1 ]; then
        echo "--------------------------"
        echo "# Cleaning AP subnet rules"
        echo "--------------------------"
        iptables -v -t nat -D PREROUTING -i $AP_SUBNET_IFACE -s $AP_SUBNET_RANGE -j TRANSOCKS
        iptables -v -D INPUT -i $AP_SUBNET_IFACE -s $AP_SUBNET_RANGE -p tcp -m tcp --dport $TRANSOCKS_PORT -j ACCEPT
    fi

    echo "-----------------------------"
    echo "# Cleaning and removing chain"
    echo "-----------------------------"
    iptables -v -F TRANSOCKS -t nat
    iptables -v -X TRANSOCKS -t nat
}

trap 'action_down' SIGINT

action_up

echo
echo "Hit Ctrl+C to remove the ip table rules"
echo


while :
do
    sleep 1
done
