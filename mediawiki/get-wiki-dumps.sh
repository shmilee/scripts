#!/bin/bash

URL=http://download.wikipedia.com
# specieswiki enwiki zhwiki enwiktionary enwikivoyage enwikinews enwikiversity zhwikibooks zhwikiquote
# See more: http://download.wikipedia.com/backup-index.html
DUMPS=('enwikibooks' 'enwikiquote' 'zhwikisource' 'enwikisource' 'specieswiki' 'zhwiki')
# Current revisions only, no talk or user pages.
# See more: http://en.wikipedia.org/wiki/Wikipedia:Database_download
SUFFIX=('pages-articles.xml.bz2')
Files=()
Urls=()
Sizes=()
ask() {
    read -n1 -t10 -p "  -> $1 [y/n]" ans
    if [ x$ans != xy -a x$ans != x ]; then
        echo " SKIP."
        return 1
    else
        echo
    fi
}

echo "ALL files will be downloaded to the current directory."
[[ -d info ]] || mkdir info
[[ -d files ]] || mkdir files
echo "==> Collecting Information ..."
>info/md5sums.txt
>files/No.pages-articles
for dump in ${DUMPS[@]}; do
    echo "  -> About $dump ..."
    curl -LfGs $URL/$dump/latest/$dump-latest-md5sums.txt >tmp-md5s.txt
    ver=$(sed -n '1s/.* //p' tmp-md5s.txt|cut -d- -f2)
    curl -LfGs $URL/$dump/$ver/ >tmp-info.html
    for suf in ${SUFFIX[@]}; do
        line=$(sed -n "/$suf$/p" tmp-md5s.txt)
        file=$(echo $line|sed 's/.*\ //')
        md5=$(echo $line|sed 's/\ .*//')
        size=$(cat tmp-info.html|grep $file | sed 's/.*<\/a> //;s/<.*//')
        if [ $suf == "pages-articles.xml.bz2" ];then
            # for pages-articles, get numbers of pages
            pagenumber=$(cat tmp-info.html|grep "<big><b>Articles"|sed 's/.*ID.*) //;s/ pages.*//')
            echo "$dump-$ver $pagenumber $size" >>files/No.pages-articles
        fi
        echo "File: $file, version $ver, size $size"
        echo "$md5 $file" >>info/md5sums.txt
        Files+=($file)
        Urls+=($dump/$ver)
        Sizes+=("$size")
    done
    mv tmp-md5s.txt info/$dump-$ver-md5sums.txt
    mv tmp-info.html info/$dump-$ver-info.html
done
echo "==> Files to be downloaded:"
i=0
while [ $i -lt ${#Files[@]} ];do
    echo "  -> $(expr $i + 1)) ${Files[$i]}, ${Sizes[$i]};"
    ((i++))
done
if ! ask "Continue?";then
    exit 1
fi
echo "==> Downloading Files ..."
i=0
>files/md5sums.txt
while [ $i -lt ${#Files[@]} ];do
    echo "  -> ($(expr $i + 1)/${#Files[@]}) ${Files[$i]} ..."
    if ask "Continue?";then
        axel -a -n 2 $URL/${Urls[$i]}/${Files[$i]} -o files/${Files[$i]}
        sed -n "/${Files[$i]}/p" info/md5sums.txt >>files/md5sums.txt
    fi
    ((i++))
done
echo "==> Checking Files ..."
cd files
if [ -s md5sums.txt ];then
    if md5sum --quiet -c md5sums.txt;then
        echo "  -> All is OK."
    else
        echo "  -> Some files are broken!"
    fi
fi
echo "==> DONE."
exit 0
