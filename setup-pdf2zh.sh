#!/bin/bash
# Copyright (C) 2025 shmilee

pdf2zh_path=~/PDFMathTranslate

PYTHON_VERSION=3.12.12
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
if ! pyenv versions | grep $PYTHON_VERSION 2>&1 >/dev/null; then
    pyenv install $PYTHON_VERSION || exit 12
fi
pyenv shell $PYTHON_VERSION

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
