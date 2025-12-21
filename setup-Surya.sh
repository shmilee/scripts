#!/bin/bash
# Copyright (C) 2025 shmilee

surya_path=~/Surya-OCR

# install for ~user
python3 -m venv "$surya_path" --prompt Surya
sed -e '/PS1=.*Surya/ s/PS1/#PS1/' \
    -e "/PS1=.*Surya/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|(Surya)\|g')\"" \
    -i $surya_path/bin/activate
source "$surya_path/bin/activate"
#python3 -m pip install torch torchvision --index-url https://mirrors.nju.edu.cn/pytorch/whl/cpu
python3 -m pip install surya-ocr \
    streamlit pdftext \
    streamlit==1.40 streamlit-drawable-canvas-jsretry

# start
#surya_gui or texify_gui
