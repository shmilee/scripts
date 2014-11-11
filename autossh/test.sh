#!/bin/bash

#passwd=$1
remote='shmilee@222.205.57.208'
port='5321'


#if [ x$passwd == x ];then
#    echo "need \$1 == passwd"
#    exit 1
#fi
if ! systemctl status sshd;then
    echo "start sshd.service first!"
    exit 2
fi

re=1
i=1

while [ $re != 0 -a $i != 3600 ];do
    if ssh -p $port $remote 'ls' 2>&1 >/dev/null;then
        echo ----[`date +%m-%d-%T`]第$i连接----
        echo "  -> Begin ..."
        #plink -N -R 3690:127.0.0.1:22 -P $port $remote -pw $passwd
        autossh -NR 3690:127.0.0.1:22 -p $port $remote
        let i++
        echo "  -> `date +%m-%d-%T`"
        echo "  -> Over. Wait 20s and reconnect."
        sleep 20
    else
        echo "  -> remote Unreachable. Wait 10s and retry."
        sleep 10
    fi
done
