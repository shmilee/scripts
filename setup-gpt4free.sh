#!/bin/bash
# Copyright (C) 2024 shmilee

gpt4free_path=~/gpt4free

# install for ~user
python3 -m venv "$gpt4free_path" --prompt GPT4Free
sed -e "/PS1=.*(GPT4Free)/ s/PS1/#PS1/" \
    -e "/PS1=.*(GPT4Free)/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|(GPT4Free)\|g')\"" \
    -i $gpt4free_path/bin/activate
source "$gpt4free_path/bin/activate"

cd "$gpt4free_path/"
python3 -m pip install -U g4f[all]
#python3 -m pip install -U g4f[webdriver]

# start
# python3 -m g4f.cli gui -port 8989 -debug
BIND="$(ifconfig eth0 | grep 'inet ' | awk '{printf $2}'):9416"
g4f api --bind $BIND --ignore-cookie-files
