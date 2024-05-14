#!/bin/bash
# Copyright (C) 2024 shmilee

gptac_path=~/gpt_academic

# install for ~user
python3 -m venv "$gptac_path" --prompt GPT
sed -e "/PS1=.*(GPT)/ s/PS1/#PS1/" \
    -e "/PS1=.*(GPT)/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|(GPT)\|g')\"" \
    -i $gptac_path/bin/activate
source "$gptac_path/bin/activate"

git clone --depth=1 https://github.com/binary-husky/gpt_academic.git "$gptac_path/gpt_academic"
python3 -m pip install -r "$gptac_path/gpt_academic/requirements.txt"

# config
cp -i -v "$gptac_path/gpt_academic/config.py" \
    "$gptac_path/gpt_academic/config_private.py"
echo "Input API_KEY, LLM_MODEL, API_URL_REDIRECT in $gptac_path/gpt_academic/config_private.py"

# start
cd "$gptac_path/"
python3 gpt_academic/main.py
