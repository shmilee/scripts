#!/usr/bin/env bash

## ranger
## Simple, vim-like file manager
## https://ranger.github.io/ranger-${Ver}.tar.gz
## depends=('python')
## optdepends=(
##     'atool: for previews of archives'
##     'elinks: for previews of html pages'
##     'ffmpegthumbnailer: for video previews'
##     'highlight: for syntax highlighting of code'
##     'libcaca: for ASCII-art image previews'
##     'lynx: for previews of html pages'
##     'mediainfo: for viewing information about media files'
##     'odt2txt: for OpenDocument texts'
##     'perl-image-exiftool: for viewing information about media files'
##     'poppler: for pdf previews'
##     'python-chardet: in case of encoding detection problems'
##     'sudo: to use the "run as root"-feature'
##     'transmission-cli: for viewing bittorrent information'
##     'w3m: for previews of images and html pages')

Ver=1.9.3
file=./ranger-${Ver}.tar.gz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar xvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd ranger-${Ver}/
        python setup.py build || exit 1
    elif [ $1 == install -o $1 == i ]; then
        cd ranger-${Ver}/
        python setup.py install --user --optimize=1 || exit 2
    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
