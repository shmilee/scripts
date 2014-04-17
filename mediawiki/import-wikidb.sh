#!/bin/bash

JarFile=mwdumper-1.16.jar

# SQL
USER=mysql user
Host=localhost
DB=your mysql db
PassWD=your passwd
str="-u $USER -h$Host -p$PassWD $DB"

# $@ = all xml.bz2 Files, sort by your self
Files=()
for file in $@; do
    if [ -f $file ];then
        Files+=($file)
    else
        echo "!!! File: $file not found."
    fi
done
echo "==> 0) TODO: ${#Files[@]} files."
i=0
for file in ${Files[@]}; do
    ((i++))
    echo "  -> $i) $file;"
done
echo "==> 1) 防止主键重复 (duplicate entry), 导入表字段字符集改为binary (page,revision,text)"
read -n1 -p "  -> Continue? [y/n]" ans
if [ x$ans != xy ];then
    echo " SKIP."
else
    echo
    mysql $str -v -e 'ALTER TABLE page DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
    mysql $str -v -e 'ALTER TABLE revision DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
    mysql $str -v -e 'ALTER TABLE text DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
fi
echo "==> 2) Delete from page,revision,text tables of database ${DB}."
read -n1 -p "  -> Continue? [y/n]" ans
if [ x$ans != xy ];then
    echo " SKIP."
else
    echo
    mysql $str -v -e 'delete from page;' ||echo "ERROR"
    mysql $str -v -e 'delete from revision;' ||echo "ERROR"
    mysql $str -v -e 'delete from text;' ||echo "ERROR"
fi
echo "==> 3) import ${#Files[@]} xml files."
i=0
for file in ${Files[@]}; do
    ((i++))
    echo "  -> ($i/${#Files[@]}) File: $file ..."
    read -n1 -p "  -> Continue? [y/n]" ans
    if [ x$ans == xy ]; then
        echo
        java -jar $JarFile --format=sql:1.5 $file |mysql $str
    else
        echo " SKIP."
    fi
done
exit 0
