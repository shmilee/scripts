#!/bin/bash
# Copyright (C) 2025 shmilee

pkgname=Umi-OCR
pkgver=2.1.5
src_url="https://github.com/hiroi-sora/Umi-OCR/releases/download/v${pkgver}/${pkgname}_Linux_Paddle_${pkgver}.tar.xz"
src_tmp=/tmp/"$(basename $src_url)"
start_sh=umi-ocr.sh

dist_PATH=~/.local/lib
dist_BIN=~/.local/bin
dist_SHR=~/.local/share

download_app() {
    wget -c $src_url -O $src_tmp
}

install_app() {
    tar Jxvf $src_tmp -C $dist_PATH
    APP_DIR="$(/bin/ls -d $dist_PATH/${pkgname}_*_${pkgver} | tail -n1)"
    APP_DIR="$(basename $APP_DIR)"
    # start script
    cat >$dist_BIN/$start_sh <<EOF
#!/bin/bash
exec $dist_PATH/$APP_DIR/$start_sh
EOF
    chmod +x $dist_BIN/$start_sh
    # .desktop
    logo="$(find $dist_PATH/$APP_DIR/ -name '*Umi-OCR*logo*' | tail -n1)"
    cat >$dist_SHR/applications/umi-ocr.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Umi-OCR
Comment=Free, Open-source, Batch Offline OCR Software.
Comment[zh_CN]=开源、免费的离线OCR软件。支持截屏/批量导入图片，PDF文档识别，排除水印/页眉页脚，扫描/生成二维码。
Exec=$dist_PATH/$APP_DIR/$start_sh
Icon=$logo
Terminal=false
StartupNotify=false
Categories=Utility;
EOF
    echo "=> DONE."
}

# main
download_app
install_app
