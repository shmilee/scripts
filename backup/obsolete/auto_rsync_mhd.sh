#!/bin/bash
SRC_DESTS=(
    "$HOME/ifts_study:/media/数据/ifts_study:--delete:--delete-excluded"
    "$HOME/ifts_study:/media/GTC-DATA/ifts_study:--delete:--delete-excluded"
    "$HOME/project:/media/store/project:--delete:--delete-excluded"
)

for s_d in ${SRC_DESTS[@]}; do
    src=$(echo $s_d | cut -d ':' -f1)
    dest=$(echo $s_d | cut -d ':' -f2)
    echo "===== $src --> $dest ====="
    deloption=$(echo $s_d | cut -d ':' -f3- | sed 's/:/ /g')
    rsyncoption='-a -v --progress'
    if [ -n "$deloption" ]; then
        echo "WARN: $deloption option is ON!"
        rsyncoption="$rsyncoption $deloption"
    fi
    if [ ! -f $src/auto_rsync_exclude ]; then
        echo "WARN: Not found auto_rsync_exclude in $src directory!"
    else
        rsyncoption="$rsyncoption --exclude-from=$src/auto_rsync_exclude"
    fi
    echo "CMD: rsync $rsyncoption $src/ $dest"
    if [ ! -d "$dest" ]; then
        echo "ERROR: Not found DEST directory '$dest'!"
	echo "vqq is in 'System Vol.. Info..'!"
    else
        read -p "Continue y/n? " ans
        if [ x$ans == 'xy' ]; then
            rsync $rsyncoption "$src/" "$dest"
        fi
    fi
done
