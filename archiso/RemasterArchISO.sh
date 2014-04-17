#!/bin/bash
## To remaster the Arch Linux ISO, a copy of the original ISO image is needed. Download it from the download page.
depends=('squashfs-tools' 'cdrkit')
export LC_ALL=C
MYVER=1.2

out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }

list() {
    local n=($(seq -w 1 ${#@})) i=0 _f
    for _f in $@; do
        echo -e "\t${n[$i]})  $_f"
        ((i++))
    done
}

track_mount() { mount "$@" && ACTIVE_MOUNTS+=("$2"); }
file_mount() { mount "$@" && FILE_MOUNTS+=("$2"); }

api_fs_mount() {
    ACTIVE_MOUNTS=()
    { mountpoint -q "$1" || track_mount "$1" "$1" --bind; } &&
    track_mount proc "$1/proc" -t proc -o nosuid,noexec,nodev &&
    track_mount sys "$1/sys" -t sysfs -o nosuid,noexec,nodev &&
    track_mount udev "$1/dev" -t devtmpfs -o mode=0755,nosuid &&
    track_mount devpts "$1/dev/pts" -t devpts -o mode=0620,gid=5,nosuid,noexec &&
    track_mount shm "$1/dev/shm" -t tmpfs -o mode=1777,nosuid,nodev &&
    track_mount run "$1/run" -t tmpfs -o nosuid,nodev,mode=0755 &&
    track_mount tmp "$1/tmp" -t tmpfs -o mode=1777,strictatime,nodev,nosuid
}

api_fs_umount() {
    ACTIVE_MOUNTS=($(echo "${ACTIVE_MOUNTS[@]}"|sed 's/ /\n/g'|sort -r))
    umount "${ACTIVE_MOUNTS[@]}"
}
file_umount() {
    # /usr/share 要在 / 之前先卸载
    FILE_MOUNTS=($(echo "${FILE_MOUNTS[@]}"|sed 's/ /\n/g'|sort -r))
    umount "${FILE_MOUNTS[@]}"
}

usage() {
    printf "RemasterArchISO %s\n" "$MYVER"
    printf -- "Usage: %s [options]\n" "$(basename $0)"
    echo
    printf -- "Options:\n"
    printf -- "  -A, --arch   <i686|x86_64>  设定架构,默认为 %s\n" "$(uname -m)"
    printf -- "  -I, --in     <路径/ISO文件> 指定原安装镜像\n"
    printf -- "  -O, --out    <ISO名称>  输出到文件(名称-%s-架构.iso),路径为当前目录,默认为 archlinux\n" "$(date +%Y.%m.%d)"
    printf -- "  -L, --label  <label>    设定ISO的标签名称,默认为 %s\n" "ARCH_$(date +%Y%m)"
    printf -- "  -S, --split  只是拆分指定架构部分，对原有fs.sfs文件不做修改\n"
    printf -- "  -v, -V       输出详细信息\n"
    printf -- "  -h, --help   显示本帮助信息\n"
    echo
}

## OPTION
SPLIT=0
O_V=""
CARCH="$(uname -m)"
OUT_NAME="archlinux"
LABEL="ARCH_$(date +%Y%m)"

OPT_SHORT="A:I:O:L:ShVv"
OPT_LONG="arch:,in:,out:,label:,split,help"
if ! OPT_TEMP="$(getopt -aq -o $OPT_SHORT -l $OPT_LONG -- "$@")";then
    usage;exit 1
fi
eval set -- "$OPT_TEMP"
unset OPT_SHORT OPT_LONG OPT_TEMP

while true; do
    case $1 in
        -A|--arch)  shift; CARCH=$1 ;;
        -I|--in)    shift; IN_ISO=$1 ;;
        -O|--out)   shift; OUT_NAME=$1 ;;
        -L|--label) shift; LABEL=$1 ;;
        -S|--split) SPLIT=1 ;;
        -V|-v)      O_V="-v" ;;
        -h|--help)  usage; exit 0 ;;
        --)         OPT_IND=0; shift; break ;;
        *)          usage; exit 1 ;;
    esac
    shift
done

ISOLINUX_FILE=$(dirname $0)/isolinux.tar.gz
OUT_FILE=${OUT_NAME}-$(date +%Y.%m.%d)-$CARCH

## BEGIN
if [[ ! -f $IN_ISO ]];then
    die "原镜像%s不存在,或未指定！" "$IN_ISO"
fi
TEMP=$(dirname $IN_ISO)/tmp-R-archiso
MNT=$TEMP/mountdir
if [[ ! -d $TEMP ]];then
    mkdir -p $TEMP||exit 1
else
    read -p "$TEMP中文件将被删除,按ENTER继续：" ANS
    if [[ x"$ANS" == x ]];then
        rm -r $TEMP
        mkdir -p $TEMP|| exit 1
    else
        exit 1
    fi
fi
(( EUID == 0 )) ||die "本脚本需要root权限实现挂载与卸载！"
trap '{ api_fs_umount; umount "$TEMP/iniso" "$MNT/etc/pacman.d/mirrorlist" "$MNT/etc/resolv.conf"; file_umount; } 2>/dev/null' EXIT

###################################--寻找文件--####################################
## 挂载原镜像
mkdir -p $O_V $TEMP/iniso
mount -o loop $IN_ISO $TEMP/iniso
files=()
for key in $CARCH/{vmlinuz,archiso.img} pkglist.$CARCH aitab checksum.$CARCH.md5; do
    files+=($(find $TEMP/iniso/ -type f|grep $key))|| msg "原镜像中未找到%s" "$key"
done
sfs=($(find $TEMP/iniso/ -type f|grep fs.sfs$|grep $CARCH))
sfs+=($(find $TEMP/iniso/ -type f|grep fs.sfs$|grep any))
msg "原镜像中找到%s个fs.sfs文件:\n%s\n==> 非sfs文件：\n%s"\
    "${#sfs[@]}" "$(list ${sfs[@]})" "$(list ${files[@]})"
mkdir -p $O_V $TEMP/files
for file in ${files[@]}; do
    msg2 "复制文件%s ..." "$(basename $file)"
    install -Dm644 $file $TEMP/files/$(basename $file)
done
if ! (($SPLIT));then
    # SFS=>FS用于img挂载,复制所需文件到$TEMP/files/
    FS_files=() # root-image.fs ...
    for file in ${sfs[@]}; do
        FS_files+=("$(basename ${file%.sfs})")
        msg2 "解压sfs文件%s ..." "$(basename $file)"
        unsquashfs -d $TEMP/files/temp $file
        mv $O_V $TEMP/files/temp/$(basename ${file%.sfs}) $TEMP/files/
        rmdir $TEMP/files/temp
    done
else
    # 不做修改，不用解压
    for file in ${sfs[@]}; do
        msg2 "复制sfs文件%s ..." "$(basename $file)"
        install -Dm644 $file $TEMP/files/$(basename $file)
    done
fi
umount "$TEMP/iniso"

###################################--做修改--####################################
if ! (($SPLIT));then
    # 挂载FS file到$MNT
    points=()
    for file in ${FS_files[@]}; do
        if ! line=$(grep ${file%.fs} $TEMP/files/aitab|grep $CARCH);then
            line=$(grep ${file%.fs} $TEMP/files/aitab|grep any)
        fi
        [[ x"$line" == x ]]&& die "%s文件的挂载点在aitab中未找到。" "$file"
        points+=($(echo $line|awk '{print $2}')::FOR::$file)
    done
    points=($(echo ${points[@]}|sed 's/ /\n/g'|sort)) # / before /usr/share
    msg "挂载信息：\n%s" "$(list ${points[@]})"
    read -p "==> 按ENTER继续,Ctrl+C退出："
    FILE_MOUNTS=()
    for p in ${points[@]}; do
        file=${p#*::FOR::}
        point=$MNT${p%::FOR::*}
        [[ -d $point ]]|| mkdir -p $O_V $point
        file_mount $TEMP/files/$file $point
    done
    api_fs_mount $MNT
    msg "准备chroot,挂载pacman以及DNS配置到%s ? [y/n]" "$MNT"
    read ANS
    [[ $ANS == "Y" || $ANS == "y" || x$ANS == x ]]&&\
        { rsync -ra $O_V /etc/pacman.d/gnupg/ $MNT/etc/pacman.d/gnupg/;
        track_mount /etc/pacman.d/mirrorlist $MNT/etc/pacman.d/mirrorlist --bind;
        track_mount /etc/resolv.conf $MNT/etc/resolv.conf --bind; }
    
    msg "Chroot到%s. 修改完成后, Ctrl+D退出." "$MNT"
    export LC_ALL=en_US.UTF-8
    case $CARCH in
        i686)    setarch i686 chroot $MNT ;;
        x86_64)  setarch x86_64 chroot $MNT ;;
        *)  msg "未知架构" ;;
    esac
    msg2 "重建pkglist文件...请耐心等待"
    for pkg in $(pacman -Q -b $MNT/var/lib/pacman/ 2>/dev/null|sed 's/ /-/'); do
        name=${pkg%-*}
        echo $(pacman -Si ${name%-*}|awk 'NR==1{printf $3}')/$pkg
    done >$TEMP/files/pkglist_tmp
    for repo in core extra community; do
        sed -n "/^$repo/p" $TEMP/files/pkglist_tmp|sort
    done >$TEMP/files/pkglist.$CARCH.txt.new
    api_fs_umount $MNT && file_umount $MNT
else
    cp $O_V $TEMP/files/pkglist.$CARCH.txt $TEMP/files/pkglist.$CARCH.txt.new
fi

###################################--重建ISO--####################################
msg "重建ISO"
mkdir -p $O_V $TEMP/outiso/arch/$CARCH # 新镜像目录
msg2 "1) 添加引导部分..."
install -Dm644 $TEMP/files/vmlinuz $TEMP/outiso/boot/vmlinuz
install -Dm644 $TEMP/files/archiso.img $TEMP/outiso/boot/archiso.img
tar zxf $ISOLINUX_FILE -C $TEMP/outiso/ $O_V
sed -i "s/%CARCH%/$CARCH/;s/%LABEL%/$LABEL/" $TEMP/outiso/isolinux/isolinux.cfg
msg2 "2) 重写aitab..."
#echo -e "# <img>\t\t<mnt>\t\t<arch>  <sfs_comp>  <fs_type>  <fs_size>" > $TEMP/outiso/arch/aitab
#for p in ${points[@]}; do
#    file=${p#*::FOR::}; file=${file%.fs}
#    point=${p%::FOR::*}
#    if [[ "$file" == "usr-share" ]];then
#        echo -e "$file\t$point\t\tany\txz\text4\t50%" >> $TEMP/outiso/arch/aitab
#    else
#        echo -e "$file\t$point\t\t$CARCH\txz\text4\t50%" >> $TEMP/outiso/arch/aitab
#    fi
#done
[[ "$CARCH" == "x86_64" ]]&& R_ARCH=i686
[[ "$CARCH" == "i686" ]]&& R_ARCH=x86_64
sed "/$R_ARCH/d" $TEMP/files/aitab > $TEMP/outiso/arch/aitab
msg2 "3) 添加pkglist文件..."
install -Dm644 $TEMP/files/pkglist.$CARCH.txt.new $TEMP/outiso/arch/pkglist.$CARCH.txt

if ! (($SPLIT));then
    msg2 "4) 压缩fs文件..."
    for file in ${FS_files[@]}; do
        if echo $file|grep -E 'usr-share.fs' >/dev/null; then
            mkdir $O_V $TEMP/outiso/arch/any
            mksquashfs $TEMP/files/$file $TEMP/outiso/arch/any/$file.sfs -noappend -comp xz
        else
            mksquashfs $TEMP/files/$file $TEMP/outiso/arch/$CARCH/$file.sfs -noappend -comp xz
        fi
    done
    msg2 "5) 更新checksum文件..."
    find $TEMP/outiso/arch/ -name aitab -o -name *.fs.sfs|xargs md5sum|sed -e "s/$(echo $TEMP/outiso/arch/|sed 's/\//\\\//g')//g" >$TEMP/outiso/arch/checksum.$CARCH.md5
else
    msg2 "4) 复制sfs文件..."
    for file in ${sfs[@]}; do
        if echo $file|grep -E 'usr-share' >/dev/null; then
            mkdir $O_V $TEMP/outiso/arch/any
            install -Dm644 $TEMP/files/$(basename $file) $TEMP/outiso/arch/any/$(basename $file)
        else
            install -Dm644 $TEMP/files/$(basename $file) $TEMP/outiso/arch/$CARCH/$(basename $file)
        fi
    done
    msg2 "5) 复制checksum文件..."
    install -Dm644 $TEMP/files/checksum.$CARCH.md5 $TEMP/outiso/arch/checksum.$CARCH.md5
fi
msg2 "6) 压缩新镜像..."
    genisoimage -l -r -J -V "$LABEL" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o ./$OUT_FILE.iso $TEMP/outiso

read -p "==>完成.删除临时目录中的文件? [y/n]" ANS
if [[ $ANS == "Y" || $ANS == "y" || x$ANS == x ]];then
    rm -r $TEMP
fi

exit 0
