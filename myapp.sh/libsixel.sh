#!/usr/bin/env bash

## libsixel
## https://github.com/saitoha/libsixel/releases/download/v1.8.6/libsixel-1.8.6.tar.gz
## depends=('curl' 'libjpeg-turbo' 'libpng')

Ver=1.8.6
file=./libsixel-${Ver}.tar.gz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar xvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd sixel-${Ver}/
        ./configure --prefix=$MYAPP || exit 1
        make || exit 2
    elif [ $1 == install -o $1 == i ]; then
        cd sixel-${Ver}/
        make install || exit 4
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
