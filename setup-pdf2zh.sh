#!/bin/bash
# Copyright (C) 2025 shmilee

pdf2zh_path=~/PDFMathTranslate

# pdf2zh 1.9.0 w/ python 3.12.8
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
pyenv shell 3.12.8

# install for ~user
python3 -m venv "$pdf2zh_path" --prompt pdf2zh
sed -e "/PS1=.*(pdf2zh)/ s/PS1/#PS1/" \
    -e "/PS1=.*(pdf2zh)/a\    PS1=\"\$(echo \"\${PS1:-}\" \| sed 's\|^\|(pdf2zh)\|g')\"" \
    -i $pdf2zh_path/bin/activate
echo "export HF_ENDPOINT=https://hf-mirror.com" >>"$pdf2zh_path/bin/activate"
echo "alias pdf2zh_ds='pdf2zh -s deepseek:deepseek-chat'" >>"$pdf2zh_path/bin/activate"
source "$pdf2zh_path/bin/activate"

cd "$pdf2zh_path/"
python3 -m pip install -U pdf2zh

# start
pdf2zh -i
