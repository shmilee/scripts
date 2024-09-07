#!/bin/bash
office='shmilee@office.zju'
SRC_DESTS=(
    "$HOME/ifts_study:/home/backup/ifts_study"
    "$HOME/project:/home/backup/project"
)

echo "please run rsync_tmbackup on same machine!!"                                                                                  
exit 1

for s_d in ${SRC_DESTS[@]}; do
    src=$(echo $s_d | cut -d ':' -f1)
    dest=$(echo $s_d | cut -d ':' -f2)
    echo "===== $src --> $office:$dest ====="
    option=$(echo $s_d | cut -d ':' -f3- | sed 's/:/ /g')
    if [ -n "$deloption" ]; then
        cmd="rsync_tmbackup.sh -p 6658 $option $src $office:$dest"
    else
        cmd="rsync_tmbackup.sh -p 6658 $src $office:$dest"
    fi
    if [ ! -f $src/auto_rsync_exclude ]; then
        echo "WARN: Not found auto_rsync_exclude in $src directory!"
    else
        cmd="$cmd $src/auto_rsync_exclude"
    fi
    echo "CMD: $cmd"
    read -p "Continue y/n? " ans
    if [ x$ans == 'xy' ]; then
        $cmd
    fi
done
