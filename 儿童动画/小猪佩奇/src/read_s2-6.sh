#!/bin/bash

# s6: http://www.iqiyi.com/a_19rrh41575.html

src="s2.html"
cmd="you-get %s -O 小猪佩奇-第2季-%s-%s.mp4"
#src="s3.html"
#cmd="you-get %s -O 小猪佩奇-第3季-%s-%s.mp4"
#src="s4.html"
#cmd="you-get %s -O 小猪佩奇-第4季-%s-%s.mp4"
#src="s5.html"
#cmd="you-get %s -O 小猪佩奇-第5季-%s.mp4"
#src="s6.html"
#cmd="you-get %s -O 小猪佩奇-第6季-%s.mp4"

for i in `seq 1 52`; do # s2
#for i in `seq 1 26`; do # s3,s4,s5,s6
    urls=($(grep "第$i集" $src | sed 's|.*<a.*href="//\(.*.html\)" .*|\1|g'))
    if [[ ${#urls[@]} -ge 2 ]] && [[ ${urls[0]} != ${urls[1]} ]]; then
        echo "-----------> 第$i集 url 出错 <----------"
        echo "${urls[@]}"
        echo "-----------> <-----------"
        continue
    fi
    url=${urls[0]}
    echo "==> 第$i集 ${#urls[@]} urls: ${urls[@]}"
    echo "==> pick $url"
    titles=($(grep "$url\" title=\"" $src | sed "s|.*$url\" title=\"\(.*\)\" rseat.*|\1|g" | sed "/^$i$/d" | sed 's| |_|g'))
    if [[ ${#titles[@]} -ge 2 &&  ${titles[0]} != ${titles[1]} ]]; then
        echo "-----------> 第$i集 title 出错 <----------"
        echo "${titles[@]}"
        echo "-----------> <-----------"
        continue
    fi
    title=${titles[0]}
    echo "==> 第$i集 ${#titles[@]} titles: ${titles[@]}"
    echo "==> pick $title"
    torun="$(printf "$cmd\n" "$url" "第$i集" "$title")" # s2 s3 s4
    #torun="$(printf "$cmd\n" "$url" "第$i集")" # s5 s6
    $torun
done
