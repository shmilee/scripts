#!/bin/bash
SRC_DESTS=(
#    "$HOME/ifts_study/zjlab-project1:/home/data-nfnas/zjlab-project1:--delete:--delete-excluded"
    "/home/data-zjhpc/GTC-DB-base2023/snapshot:/media/GTC-DATA/GTC-DB-base2023/snapshot"
    "/home/data-zjhpc/GTC-DB-base2023/zetapsi3d:/media/GTC-DATA/GTC-DB-base2023/zetapsi3d"
    "/home/data-zjhpc/GTC-DB-base2023/flux3d:/media/GTC-DATA/GTC-DB-base2023/flux3d"
#    "/home/data-zjhpc/snap20231214/snapshot:/home/shmilee/ifts_study/research/04-nonlinear-simulation-ITG-TEM-isotope-effect/20231214-nonlinear-ITGak/snapshot"
#    "/home/data-zjhpc/snap20231214/zetapsi3d:/home/shmilee/ifts_study/research/04-nonlinear-simulation-ITG-TEM-isotope-effect/20231214-nonlinear-ITGak/zetapsi3d"
#    "/home/data-zjhpc/snap20231214/flux3d:/home/shmilee/ifts_study/research/04-nonlinear-simulation-ITG-TEM-isotope-effect/20231214-nonlinear-ITGak/flux3d"
)

for s_d in ${SRC_DESTS[@]}; do
    src=$(echo $s_d | cut -d ':' -f1)
    dest=$(echo $s_d | cut -d ':' -f2)
    echo "===== $src --> $dest ====="
    deloption=$(echo $s_d | cut -d ':' -f3- | sed 's/:/ /g')
    rsyncoption='-a -v --progress --append-verify'
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
    else
        read -p "Continue y/n? " ans
        if [ x$ans == 'xy' ]; then
            rsync $rsyncoption "$src/" "$dest"
        fi
    fi
done
