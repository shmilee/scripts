#!/usr/bin/env bash

## lua, argparse, luaprompt
## https://github.com/dpapavas/luaprompt
## depends=("lua" "lua-argparse")
sources=(
  "https://github.com/dpapavas/luaprompt/archive/v0.7.tar.gz"
  "https://www.lua.org/ftp/lua-5.3.6.tar.gz"
  "https://raw.githubusercontent.com/luarocks/argparse/0.7.1/src/argparse.lua"
)

pkgver=0.7
file=./luaprompt-$pkgver.tar.gz
luafile=./lua-5.3.6.tar.gz
luaver=5.3.6
argparse=./argparse-0.7.1.lua

## skip TH3 flags: MYCFLAGS=" " MYLDFLAGS=" "  bash luaprompt.sh b
readline_path='/vol7/software/readline/8.0-gcc4.9.3'
MYCFLAGS=${MYCFLAGS:-"-I${readline_path}/include"}
MYLDFLAGS=${MYLDFLAGS:-"-L${readline_path}/lib -lncurses"}

MYAPP=${MYAPP:-"$HOME/.local"} ## /usr

if [[ -n "$1" ]];then
    if [ $1 == download -o $1 == d ]; then
        wget -c ${sources[0]} -O ${file}
        wget -c ${sources[1]} -O ${luafile}
        wget -c ${sources[2]} -O ${argparse}
    elif [ $1 == extract -o $1 == e ]; then
        tar zxvf ${file}
        tar zxvf ${luafile}
    elif [ $1 == build -o $1 == b ]; then
        cd lua-$luaver/
        sed -i "s|\(LUA_ROOT.*\)/usr/local/|\1$MYAPP/|" src/luaconf.h
        make INSTALL_TOP=$MYAPP linux MYCFLAGS="${MYCFLAGS}" MYLDFLAGS="${MYLDFLAGS}" || exit 91
        make INSTALL_TOP=$MYAPP install || exit 92
        cd ../
        install -Dm644 ${argparse} $MYAPP/share/lua/5.3/argparse.lua
        cd luaprompt-$pkgver/
        make PREFIX=$MYAPP LUA_CFLAGS="-I$MYAPP/include ${MYCFLAGS}" LUA_LDFLAGS="${MYLDFLAGS}" || exit 1
    elif [ $1 == install -o $1 == i ]; then
        cd luaprompt-$pkgver/
        make PREFIX=$MYAPP install || exit 2
    else
        echo "Usage: $0 [download|extract|build|install]"
    fi
else
    echo "Usage: $0 [download|extract|build|install]"
fi
