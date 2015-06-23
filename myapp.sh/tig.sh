#!/usr/bin/env bash

## tig
## http://jonas.nitro.dk/tig/releases/tig-$Ver.tar.gz
## depends=('git' 'ncurses')
## makedepends=('asciidoc' 'xmlto')

Ver=2.1.1
file=./tig-${Ver}.tar.gz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar zxvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd tig-${Ver}/
        ./configure --prefix=$MYAPP --sysconfdir=$MYAPP/etc || exit 1
        make || exit 2
    elif [ $1 == install -o $1 == i ]; then
        cd tig-${Ver}/
        make install || exit 3
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
