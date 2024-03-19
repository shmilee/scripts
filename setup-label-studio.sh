#!/bin/bash
# Copyright (C) 2024 shmilee

studio_path=~/label-studio

# install for ~user
python3 -m venv "$studio_path" --prompt LABEL
sed -e "/PS1=.*(LABEL)/ s/PS1/#PS1/" \
    -e "/PS1=.*(LABEL)/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|(LABEL)\|g')\"" \
    -i $studio_path/bin/activate
source "$studio_path/bin/activate"
python3 -m pip install label-studio
echo "export LABEL_STUDIO_DISABLE_SIGNUP_WITHOUT_LINK=true" >> "$studio_path/bin/activate"
echo "export LABEL_STUDIO_BASE_DATA_DIR=$studio_path/data" >> "$studio_path/bin/activate"
mkdir "$studio_path/data"

# add localhost usernames
for i in `seq 1 10`; do
    who="$(tr -dc a-z </dev/urandom | head -c 5)@localhost"
    key="pWd+$(cat /proc/sys/kernel/random/uuid | cut -d- -f3)$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"
    echo -e "$i  $who  $key\n" >> "$studio_path/user-info"
    label-studio start -b --username "$who" --password "$key"
done

# check
#label-studio user --username ?name?from?user-info?
#label-studio start
