#!/bin/bash
# Copyright (C) 2024 shmilee

DIST_path=~/qq-QChatGPT
LABEL=QChatGPT

# install for ~user
python3 -m venv "$DIST_path" --prompt $LABEL
sed -e "/PS1=.*($LABEL)/ s/PS1/#PS1/" \
    -e "/PS1=.*($LABEL)/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|($LABEL)\|g')\"" \
    -i $DIST_path/bin/activate
source "$DIST_path/bin/activate"

cd "$DIST_path"
git clone --depth 1 https://github.com/RockChinQ/QChatGPT
python3 -m pip install -r QChatGPT/requirements.txt

# 配置
cat << EOF
QChatGPT/data/config/platform.json

        {
            "adapter": "aiocqhttp",
            "enable": true,
            "host": "127.0.0.1",
            "port": 9574,
            "access-token": ""
        },

    "force-delay": [1, 5],

QChatGPT/data/config/provider.json

    "keys": {
        "openai": [
            "sk-AAAAAAAAAAAABBBBBBBBBBBBCCCCCCCCCCCCCDDDDDDDDD"
        ],
        "anthropic": [],
        "moonshot": [],
        "deepseek": []
    },

        "openai-chat-completions": {
            "base-url": "https://api.chatanywhere.com.cn/v1",
            "args": {},
            "timeout": 120
        },

    "model": "gpt-4o-mini",


QChatGPT/data/config/system.json

    "admin-sessions": [
        "person_9xxxxxxxx"
    ],

EOF

# start
cd QChatGPT/
python3 main.py
