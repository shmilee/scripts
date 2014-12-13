#!/usr/bin/sh
if [ "$PWD" != "`dirname $0`" -a "`dirname $0`" != '.' ];then
    cd `dirname $0`
    echo "!=> Working Here:"
    pwd
fi
ipython nbconvert --config ./nbconvert_config.py "$@"
