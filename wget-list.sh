#!/bin/bash
# wget -i url-list 
# usage: wget-list.sh list-file
# cat list-file
# name1::url1
# name2::url2
# ... ...

list="$1"
if [[ ! -f $list ]];then
    echo "$list not exit."
    exit 1
fi
nlist=$(awk 'END {print NR}' $list)
fail_names=()
fail_lines=()
for i in $(seq 1 1 $nlist)
do
    line="$(awk 'NR=='$i'{print $0}' $list)"
    if ! echo $line|grep :: 2>&1 >/dev/null ;then
        echo "wrong line : $i"
        fail_lines+=("$i")
    else
        name="${line%%::*}"
        url="${line##*::}"
        wget -t 3 -c -O "$name" "$url"
        if [[ "$?" != "0" ]];then
            echo "Faild to download ${name}."
            fail_names+=("$name")
        fi
    fi
done
echo "ALL DONE!"
[[ "${#fail_names[@]}" == "0" ]] || echo -e "Faild files:\n ${fail_names[@]}"
[[ "${#fail_lines[@]}" == "0" ]] || echo -e "Faild lines:\n ${fail_lines[@]}"
