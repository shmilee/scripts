#!/bin/bash
# file: init.sh customexec.conf synergy.conf

if [ x$1 == xS -o x$1 == xs ]; then
    echo "==> Server for user: $USER"
    echo " -> rm old ~/.synergy/, create new one."
    rm -r ~/.synergy/
    mkdir -pv ~/.synergy/{plugins,SSL/Fingerprints}
    ln -sv /usr/lib/synergy/libns.so ~/.synergy/plugins/libns.so
    openssl req -x509 -nodes -days 365 -subj /CN=Synergy -newkey rsa:1024 \
        -keyout ~/.synergy/SSL/Synergy.pem -out ~/.synergy/SSL/Synergy.pem
    openssl x509 -fingerprint -sha1 -noout -in ~/.synergy/SSL/Synergy.pem \
        > ~/.synergy/SSL/Fingerprints/Local.txt
    sed -e "s/.*=//" -i ~/.synergy/SSL/Fingerprints/Local.txt
    echo " -> add configuration file"
    cp -v ./synergy.conf ~/.synergy/synergy.conf
    install -Dvm644 ./usynergys.service ~/.config/systemd/user/usynergys.service
    systemctl --user daemon-reload
    systemctl --user enable usynergys
    echo " -> !! Edit your /etc/hosts, by yourself!"
    echo " -> !! Do not forget add the fingerprint to your client!!!"
    echo " -> !! Here it is: $(<~/.synergy/SSL/Fingerprints/Local.txt)"
    echo "==> Done."
elif [ x$1 == xC -o x$1 == xc ]; then
    echo "==> Client for user: $USER"
    echo " -> rm old ~/.synergy/, create new one."
    rm -r ~/.synergy/
    mkdir -pv ~/.synergy/{plugins,SSL/Fingerprints}
    ln -sv /usr/lib/synergy/libns.so ~/.synergy/plugins/libns.so
    echo " -> add the server FingerPrint"
    read -p " -> Input FP:" FFPP
    echo $FFPP >~/.synergy/SSL/Fingerprints/TrustedServers.txt
    echo " -> !! Run command to engoy:"
    echo " -> !! \$ synergyc -f --enable-crypto <Server IP>"
    echo "==> Done."
else
    echo "$0 <S|C>"
    echo "  S: Server"
    echo "  C: Client"
fi
