#!/bin/bash
if [ x$1 == x -o x$2 == x ];then
    echo "usage: scmd.sh [input.file] [output.file] [L/R] [T/B]"
    exit 1
fi
if [ ! -f $1 ];then
    echo "Cannot find input.file: $1!"
    exit 2
fi
AS='y'
if [ -f $2 ];then
    read -p "output.file:$2 exists, overwrite it? [y/n]" AS
fi
in=$1
out=$2
[ ! -z $3 ]&& GEOMETRY="-V geometry:left=$3,right=$3"
[ ! -z $4 ]&& GEOMETRY+=",top=$4,bottom=$4"
if [ x$AS == xy ];then
    pandoc -N --template=xelatex-cjk.tex --latex-engine=xelatex \
         $GEOMETRY --toc $1 -o $2
    echo "DONE."
fi
exit 0
