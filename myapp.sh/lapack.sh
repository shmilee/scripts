#!/usr/bin/env bash

## lapack
## http://www.netlib.org/lapack/lapack-$Ver.tgz
## makedepends=('gcc-fortran' 'cmake')
## depends=('gcc-libs')

Ver=3.5.0
file=./lapack-$Ver.tgz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar zxvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd lapack-${Ver}/
        cmake . \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_SKIP_RPATH=ON \
          -DBUILD_SHARED_LIBS=ON \
          -DCMAKE_INSTALL_PREFIX=$MYAPP \
          -DCMAKE_Fortran_COMPILER=ifort \
          -DLAPACKE=ON || exit 1
        make || exit 2
    elif [ $1 == install -o $1 == i ]; then
        cd lapack-${Ver}/
        #for libname in liblapack libtmglib liblapacke libblas; do
        #    install -m755 "lib/${libname}.so" "$MYAPP/lib/"
        #    ln -sf ${libname}.so "$MYAPP/lib/${libname}.so.${pkgver}"
        #    ln -sf ${libname}.so "$MYAPP/lib/${libname}.so.3"
        #done
        #install -m755 bin/* "$MYAPP/bin"
        #install -m644 include/* "$MYAPP/include"
        make install || exit 3
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
