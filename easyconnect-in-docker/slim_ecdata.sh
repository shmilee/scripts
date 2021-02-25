#!/bin/bash
# Copyright (C) 2021 shmilee

# EC versions to slim, 7.6.3, 7.6.7
VERSIONa="${1:-7.6.3}"
VERSIONb="${2:-7.6.7}"
# EC data repo dir
DATAREPO="${3:-./ECDATA}"

HOSTECDIRa="${DATAREPO}/EasyConnect_x64_v$VERSIONa"
HOSTECDIRb="${DATAREPO}/EasyConnect_x64_v$VERSIONb"

# ln $relativea/* $realpathb/* if md5sum equal
ln_equal() {
    relativea="$1"
    realpathb="$2"
    oldPWD="$PWD"
    cd "${realpathb}"
    for f in `ls .`; do
        if [ -f "${relativea}/$f" ]; then
            md5a=`md5sum ${relativea}/$f | awk '{print $1}'`
            md5b=`md5sum $f | awk '{print $1}'`
            if [ "$md5a" = "$md5b" ]; then
                mv $f $f-bk
                ln -v "${relativea}/$f" $f && rm $f-bk || mv $f-bk $f
            fi
        fi
    done
    cd "${oldPWD}"
}


if [ ! -d $HOSTECDIRa ]; then
    echo ">> lost Dir $HOSTECDIRa of version $VERSIONa!"
    exit 1
fi
if [ ! -d $HOSTECDIRb ]; then
    echo ">> lost Dir $HOSTECDIRb of version $VERSIONb!"
    exit 1
fi
ln_equal "../EasyConnect_x64_v$VERSIONa" "$HOSTECDIRb"
ln_equal "../../../EasyConnect_x64_v$VERSIONa/resources/lib64" \
    "$HOSTECDIRb/resources/lib64"
