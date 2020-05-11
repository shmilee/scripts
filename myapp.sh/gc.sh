#!/usr/bin/env bash

## gc
## https://github.com/ivmai/bdwgc/releases/download/v${Ver}/gc-${Ver}.tar.gz
## add_stack_bottom_feature.patch::https://github.com/ivmai/bdwgc/commit/5668de71107022a316ee967162bc16c10754b9ce.patch
## depends=('gcc-libs')

Ver=8.0.4
file=./gc-${Ver}.tar.gz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar xvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd gc-${Ver}/
        patch -p1 < ../add_stack_bottom_feature.patch
        ./configure --prefix=$MYAPP --enable-cplusplus --disable-static \
            || exit 1
        sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
        make || exit 2
    elif [ $1 == install -o $1 == i ]; then
        cd gc-${Ver}/
        make install || exit 4
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
