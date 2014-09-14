#!/bin/bash

usage() {
    cat <<EOF

 用法：
    slim_BB.sh [ROM_directory]
    注：删除的模块存放于 ROM_directory/trash, 目录最好不要有空格
EOF
}

list() {
    local n=($(seq -w $1 $((${#@}+$1-3)))) i=0 _f
    for _f in ${@:3}; do
        (($i%$2==0)) && echo -e -n "\t" # indent
        echo -e -n "${n[$i]}) $_f\t"
        (( $i%$2 == $(($2-1)) )) && echo # \n
        ((i++))
    done
    (($i%$2==0)) ||echo # aliquant \n
}

in_array() {
    local s
    for s in ${@:2}; do
        if [[ $s == $1 ]];then
            return 0
        fi
    done
    return 1
}

ask() {
    local msg=$1 answ
    read -p "==> $msg [y/n] " answ
    if [ x$answ == 'xy' -o x$answ == 'xY' -o x$answ == 'xyes' ];then
        return 0
    else
        return 1
    fi
}

## 特殊的：若$1 = '-at', $2 = t, 则在询问时等待t秒后，没有输入的话会删除所有cod
# 两种格式 'a.cod,::desc' 'b.cod,::desc' ... 或者 'a.cod' 'b.cod' ...
select_del() {
    local opt_t word cods _select num cod desc

    if [ x$1 == 'x-at' ];then
        opt_t="-t $2"
        word="若$2 秒后无输入，视为默认删除所有！ "
        cods=(${@:3})
    else
        opt_t=""
        cods=($@)
    fi
    echo -e "    -> ${#cods[@]}个cod文件:\n$(list 1 1 ${cods[@]})"
    echo "==> 请输入要删除的文件对应的序号。如, 1 3 5, or all"
    [[ x$word != x ]] && echo "==> $word"
    read $opt_t -p "==>  输入: " -a _select
    if [ x$_select == xall -o x$1 == 'x-at' -a x$_select == x ];then
        echo "==> 删除所有cod."
        _select=($(seq 1 1 ${#cods[@]}))
    fi
    if [ x$_select == x -a x$1 != 'x-at' ];then
        echo "==> 保留所有cod."
        return 0
    fi
    for num in ${_select[@]}; do
        cod=${cods[$(expr $num - 1)]}
        echo "    -> 删除$cod ..."
        desc=${cod#*,::}
        [[ $desc == $cod ]] && desc="" #无描述
        cod=${cod%,::*}
        if [ -f ./Java/$cod ];then
            mv -v ./Java/$cod ./trash/Java/
            echo "(cod) $cod :: $desc" >>del.txt
        else
            echo "==> $cod not found in Java."
        fi
    done
}

## 按组删除 $@ = 所有的组
del_groups() {
    local i group cods groups=($@)
    echo -e "==> 现在共有${#groups[@]}组, 他们分别是:\n$(list 1 5 ${groups[@]})"
    echo "==> 开始逐组删减..."
    i=0
    for group in ${groups[@]}; do
        ((i++))
        echo "==> ($i/${#groups[@]}) 关于$group ..."
        cods=($(ls ./Java/*$group* 2>/dev/null | sed 's|./Java/||g'))
        if in_array $group ${KEYS[@]};then  ## 用 KEYS 
            select_del ${cods[@]} # 询问删除
        else
            select_del -at 1 ${cods[@]} #5秒后自动删除
        fi
    done
}

##  cd [ROM_directory], then slim_alx, im game bis ...
slim_alx() {
    local alx_name name i cods cod desc num sugg left_alx
    alx_name=($(ls ./*.alx))
    echo -e "==> 这里有${#alx_name[@]}个alx文件, 他们分别是:\n$(list 1 4 ${alx_name[@]})"
    echo "==> 开始逐个删减..."
    i=0
    for name in ${alx_name[@]}
    do
        ((i++))
        echo "==> ($i/${#alx_name[@]}) 关于 $name ..."
        ## 准备
        grep .cod $name|sed 's/<files>//g;s/<\/files>//g;s/^[ ]*//g;s/^\t*//g;s/[ ]*$//g' >$TEMP/tmp
        # win unix 文本 啊啊啊 烦人
        sed 's/.$//g' $TEMP/tmp >$TEMP/$name
        cods=($(cat $TEMP/$name))
        desc="$(grep -m1 description $name|sed 's/^.*<description>//g;s/<\/description>.*$//g')"
        if [[ ! -n "$(echo $desc|sed 's/.$//')" ]];then
            unset num
            num=$(grep -n -m1 description $name|cut -d: -f1)
            ((num++))
            desc=$(sed -n "${num}p" $name|sed 's/^[ ]*//g;s/^\t*//g;s/[ ]*$//g')
            if echo $desc|grep -q 'loader version';then
                desc="无"
            fi
        fi
        ## 询问
        echo -e "    -> cod文件: ${#cods[@]}个, 分别是:\n$(list 1 1 ${cods[@]})"
        echo "    -> 描述:$desc"
        sugg=""
        if [[ ${#cods[@]} == 0 ]];then
            sugg="由于$(basename $name)无cod文件，建议您删除."
        fi
        if ask "删除${name}所有？$sugg";then
            echo "==> 删除 $name ..."
            echo "(alx) $name :: $desc" >>del.txt
            ## 开始删除
            mv -v $name ./trash/
            if [[ ${#cods[@]} != 0 ]];then
                for cod in ${cods[@]}; do
                    if [ -f ./Java/$cod ];then
                        mv -v ./Java/$cod ./trash/Java/
                        echo "(cod) $cod ($name)" >>del.txt
                    else
                        echo "==> $cod not found in Java."
                    fi
                done
            fi
        else
            echo "==> 保留 $name."
        fi
    done
    left_alx=($(ls ./*.alx))
    echo -e "==> 处理alx文件${#alx_name[@]}个，剩余${#left_alx[@]}个, 他们分别是:\n$(list 1 4 ${left_alx[@]})"
    list 1 1 ${left_alx[@]} >keep.txt
    echo
}

## cd [ROM_directory], then slim_lang
slim_lang() {
    local la _tmp=()
    echo "==> 1) 按语言简写(如en,zh,fr)初步删减。"
    del_groups ${langs[@]}
    echo "==> 2) 按语言全称(国家)搜索去除部分语言支持。"
    del_groups ${LANGS[@]}
    echo "==> 3) 仓颉 注音 输入法。依赖复杂，体积不大，3M左右，都保留吧。"
    input_cods=('net_rim_tid_chinese_jni_trad.cod,::繁体注音'
                'net_rim_tid_chinese_CangJei.cod,::繁体仓颉'
                'net_rim_tid_chinese_CangJeiSimpl.cod,::简体仓颉'
                'net_rim_platform_resource__zh_CN_CangJei.cod'
                'net_rim_platform_resource__zh_TW_CangJei.cod'
                'net_rim_tid_chinese_stroke_trad.cod'
                'net_rim_tid_dynamic_ling_data_chinese_Stroke_wordlist.cod'
                'net_rim_tid_dynamic_ling_data_chinese_TW_wordlist.cod'
                'net_rim_tid_dynamic_ling_data_chinese_Wubizixing_wordlist.cod'
                'net_rim_tid_chinese_cj_core.cod,::仓颉core') # 坑爹的jei
    list 1 1 ${input_cods[@]}
}

## 道听途说可删除的cod
slim_dtts() {
    echo "==> 1) 语音拨号。"
    vad_cods=($(ls ./Java/net_rim_vad*.cod|sed 's|./Java/||g'))
    select_del ${vad_cods[@]}
    echo "==> 2) 杂项。"
    other_cods=('net_rim_font_georgia.cod,::字体格鲁吉亚'
                'net_rim_tid_dynamic_transcoding_data_TIS620.cod,::thai字符支持'
                'net_rim_bb_browser_plugin_docview.cod,::附件服务'
                'net_rim_phone_tty_enabler.cod,::盲人辅助'
                'net_rim_cellbroadcast.cod,::小区广播'
                'net_rim_bb_app_center.cod,::软件中心'
                'net_rim_event_log_viewer_app.cod,::系统日志'
                'net_rim_bb_activation.cod,::企业激活')
    select_del ${other_cods[@]}
}

## MAIN
if [[ -z "$1" ]];then
    echo "ERROR :: ROM目录在哪里呀？亲，告诉人家嘛！"
    usage
    exit 1
fi
if [[ ! -d "$1" ]];then
    echo "ERROR :: 目录！ROM目录！别忽悠我不认识目录！"
    usage
    exit 2
fi
if [ ! -f "$1"/BlackBerry.alx ];then
    echo "ERROR :: 这货不是ROM所在的目录！别忽悠我哦！"
    usage
    exit 3
fi
TEMP=/tmp/slim_BB_ROM_$(date +%F)
[[ -d $TEMP ]] && rm -r $TEMP
mkdir $TEMP
[[ -d "$1"/trash/Java ]] ||  mkdir -pv "$1"/trash/Java
cd "$1"
>del.txt #存放删除记录

# 语言简称
# ls ./Java/*__*.cod|sed 's/.*__//g;s/\.cod//g'|sort -u
# 特别 vi__MultiTap, 忽略zh_CN_{CangJei,Pinyin,WuBiHua} zh_TW_{Bopomofo,CangJei,Pinyin,Strokes}
langs=(af ar ca cs da de el 'en' 'en_GB' en_NL 'en_US' es es_MX eu fr fr_CA gl
       he he_IL he_US hi hu id it 'ja' 'ko' nl no pl pt pt_br pt_BR pt_PT ro ru sv th tr
       vi vi__MultiTap 'zh' 'zh_CN' 'zh_HK' 'zh_TW')
# 语言全称
# net_rim_tid_dynamic_ling_data*, 去除domain misspellings financial legal medical
# sed 's/.*data_//g;s/_.*//g;/domain/d;/financial/d;/legal/d;/medical/d;/misspellings/d'|sort -u
# 根据net_rim_tid_*, 添加indic Korean vietnamese Japanese
LANGS=(afrikaans arabic catalan 'chinese' czech danish dutch 'english' french german greek
       hebrew hungarian indic italian 'Japanese' 'japanese' 'Korean' 'korean' norwegian
       polish portuguese romanian russian spanish swedish thai turkish vietnamese)

# keys=保留关键字, 询问确认后再删除，而其余的语言默认自动删除
keys=(en en_GB en_US zh zh_CN) #  ja ko zh_HK zh_TW)
KEYS=(chinese english) # Japanese japanese Korean korean)

if ask "第一步, 按照alx文件删除不需要的软件？";then
    slim_alx
else
    echo "==> 跳过。"
fi
if ask "第二步, 删除不需要的语言，输入法，文字支持等？";then
    # 处理一下 keys langs 两个数组
    for k in ${keys[@]}; do
        KEYS+=(_${k}.cod) ##保留关键字都存放于 KEYS 中
    done
    for i in $(seq 0 1 $(expr ${#langs[@]} - 1)); do
        langs[$i]="_${langs[$i]}.cod"
    done
    slim_lang
else
    echo "==> 跳过。"
fi
if ask "第三步, 删除某些其他不用的cod文件？";then
    slim_dtts
else
    echo "==> 跳过。"
fi
echo "==> 瘦身完成。"
exit 0
