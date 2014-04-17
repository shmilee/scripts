#!/bin/bash
# need: 1) xml backup files, mwdumper; 2) mediawiki, base.sql, LocalSettings.php; 3) LAMP
# $@ = all xml.bz2 Files sorted by yourself
# for each xml.bz2 file 
#     create a database named as the file, like enwikibooksdb
#     source base.sql
#     import xml file to the database, db size ? No. of pages and xml size
#     create subwiki(ln -s) named as the file, like enwikibooks
#     edit LocalSettings.php for the subwiki
#     rebuild text index, db size = text.ib size
# done

check_file() {
    for file in $@; do
        if [ ! -f $file ];then
            echo "!!! $file not found!"
            exit 1
        fi
    done
}
ask() {
    read -n1 -t10 -p "  -> $1 [y/n]" ans
    if [ x$ans != xy -a x$ans != x ]; then # default yes
        echo " SKIP."
        return 1
    else
        echo
    fi
}
add_subwiki() {
    local file=$1
    local name=$(basename $file)
    local name=${name%%-*} # subwiki dir name
    local DB=${name}db
    local fd
    read -p "==> input a sitename, like mywiki: " sitename

    echo "  -> 1)create database $DB ..."
    if mysql $Connect -e "use $DB;" 2>/dev/null;then
        if ask "WARNNING: $DB exists, drop it first!";then
            mysql $Connect -v -e "drop database $DB;" ||echo "ERROR"
        else
            return
        fi
    fi
    mysql $Connect -v -e "create database $DB;" ||echo "ERROR"

    echo "  -> 2)source base.sql ..."
    sed "s/%WIKIDB%/$DB/g" $BASEDB >tmp.sql
    mysql $Connect -e "source tmp.sql;" ||echo "ERROR"
    rm tmp.sql

    echo "  -> 3) import xml file ..."
    if ask "duplicate entry, set DEFAULT CHARSET=binary for tables page,revision,text of $DB ?";then
        mysql $Connect $DB -v -e 'ALTER TABLE page DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
        mysql $Connect $DB -v -e 'ALTER TABLE revision DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
        mysql $Connect $DB -v -e 'ALTER TABLE text DEFAULT CHARACTER SET BINARY;' ||echo "ERROR"
    fi
    if ask "Delete * from tables page,revision,text of $DB ?";then
        mysql $Connect $DB -v -e 'delete from page;' ||echo "ERROR"
        mysql $Connect $DB -v -e 'delete from revision;' ||echo "ERROR"
        mysql $Connect $DB -v -e 'delete from text;' ||echo "ERROR"
    fi
    echo "  -> importing may take a long time, U can leave me alone."
    java -jar $MWDUMPER --format=sql:1.5 $file | mysql $Connect $DB

    echo "  -> 4) create subwiki $name ..."
    if [ -d $SUBroot/$name ];then
        if ask "Directory $SUBroot/$name exists, remove it?";then
            rm -r $SUBroot/$name
            mkdir -v $SUBroot/$name
        fi
    else
        mkdir -v $SUBroot/$name
    fi
    for fd in $WIKIDIR/*; do
        ln -s $fd $SUBroot/$name/
    done

    echo "  -> 5) edit LocalSettings.php ..."
    sed -e "s/%SITENAME%/$sitename/;s/%NAME%/$name/;s/%HOST%/$HOST/"\
        -e "s/%DB%/$DB/;s/%USER%/$USER/;s/%PASSWD%/$PassWD/" $SETTING >$SUBroot/$name/LocalSettings.php

    echo "  -> 6) rebuild text index with LocalSettings.php ..."
    if ask "Continue?";then
        php $WIKIDIR/maintenance/rebuildtextindex.php --conf $SUBroot/$name/LocalSettings.php
    fi

    echo "  DONE."
}

WIKIDIR=/usr/share/webapps/mediawiki/ # link to
SUBroot=/srv/http # subwiki root path
MWDUMPER=mwdumper-1.16.jar
BASEDB=base.sql
SETTING=LocalSettings.php
check_file $MWDUMPER $BASEDB $SETTING
if [ ! -d $WIKIDIR ];then
    echo "!!! Mediawiki Directory: $WIKIDIR not found!"
    exit 1
fi
if [ ! -d $SUBroot ];then
    echo "!!! Subwiki Root Directory: $SUBroot not found!"
    exit 1
else
    if ! touch $SUBroot/temp-test.test;then
        echo "!!! Create file in $SUBroot: Permission denied."
        exit 1
    else
        rm $SUBroot/temp-test.test
    fi
fi

# SQL
read -p "==> input mysql user name: " USER
read -p "==> input host name: " HOST
read -s -p "==> input password: " PassWD
echo
Connect="-u $USER -h$HOST -p$PassWD"
if ! mysql $Connect -e 'quit' 2>/dev/null;then
    echo "!!! ERROR: connect to mysql."
    exit 2
fi

# xml files
Files=()
for file in $@; do
    if [ -f $file ];then
        Files+=($file)
    else
        echo "!!! File: $file not found."
    fi
done
echo "==> START: ${#Files[@]} files to do."
i=0
for file in ${Files[@]}; do
    ((i++))
    echo "  -> $i) $file;"
done

# START
i=0
for file in ${Files[@]}; do
    ((i++))
    echo "==> ($i/${#Files[@]}) File: $file ..."
    if ask "Continue?";then
        add_subwiki $file
    fi
done
exit 0
