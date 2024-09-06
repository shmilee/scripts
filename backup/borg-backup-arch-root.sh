#!/bin/bash
# Copyright (C) 2024 shmilee

BACKSRC="/"
BACKDIST="$(dirname "$(realpath $0)")"/borg-arch-root-backup

Encryption="none"
Compression="zstd,9"

Excludefile="$(mktemp -u -t 'borg.root.exclude.file.XXXXX')"
Excludeinfo="$(mktemp -u -t 'borg.root.exclude.info.XXXXX')"
Exclude_patterns=(
    '/dev/*'
    '/proc/*'
    '/sys/*'
    '/tmp/*'
    '/run/*'
    '/mnt/*'
    '/media/*'
    '/lost+found/'
    '/home/*'
    '/boot/vmlinuz-*'
    '/boot/initramfs-*.img'
    '/var/cache/pacman/pkg/*'
    '/var/cache/pkgfile/*'
    '/var/cache/fontconfig/*'
)
# Sort by size
# LC_ALL=C.UTF-8 pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h
# yay -Ps
Exclude_pkgs=(
    'dingtalk-bin'
    'wpsoffice'
    'nvidia-utils' 'lib32-nvidia-utils'
    'wine'
    'dict-oxford-ald'
    'linuxqq'
    'baidunetdisk-bin'
    'google-chrome'
    'wemeet-bin'
    'wechat-uos'
    'zoom'
    'qt6-webengine' 'qt5-webengine'
    'go'
    'clang'
    'gcc'
    'electron19-bin'
    'virtualbox'
    'wyabdcrealpeopletts'
    'texlive-fontsrecommended' 'texlive-langchinese'
    'jre-openjdk'
    'webkit2gtk'
    'gimp'
)

update_excludefile() {
    printf '' >"${Excludefile}"
    echo "Patterns:" >"${Excludeinfo}"
    for pat in "${Exclude_patterns[@]}"; do
        printf "$pat\n" >>"${Excludefile}"
        echo "  $pat" >>"${Excludeinfo}"
    done
    echo "Packages:" >>"${Excludeinfo}"
    for pkg in "${Exclude_pkgs[@]}"; do
        pacman -Ql $pkg 2>/dev/null | awk '{print $2}' | grep -v '/$' | grep -v '^/etc/' >>"${Excludefile}"
        echo "  $pkg" >>"${Excludeinfo}"
    done
    sudo cp -v "${Excludeinfo}" "/.borg.root.exclude.info"
}

create_archive() {
    cat << EOF

    BACKSRC     = ${BACKSRC}
    BACKDIST    = ${BACKDIST}
    Encryption  = ${Encryption}
    Compression = ${Compression}
    Excludefile = ${Excludefile}
    Excludeinfo = ${Excludeinfo}

    Create CMD: borg create -s --progress \\
        --compression ${Compression} \\
        --exclude-from ${Excludefile} \\
        ${BACKDIST}::{hostname}-{now:%Y-%m-%d} ${BACKSRC}
EOF
    sudo borg create -s --progress \
        --compression ${Compression} \
        --exclude-from ${Excludefile} \
        ${BACKDIST}::{hostname}-{now:%Y-%m-%d} ${BACKSRC}
}

if [ "$1" = "init" ]; then
    sudo borg init --encryption=${Encryption} "${BACKDIST}"
elif [ "$1" = "show" ]; then
    sudo borg info "${BACKDIST}"
    echo -e '\n------------------------------------------------------------------------------'
    sudo borg list "${BACKDIST}"
    echo -e '------------------------------------------------------------------------------\n'
    sudo borg info "${BACKDIST}" --last 1
elif [ "$1" = "create" ]; then
    update_excludefile
    create_archive
elif [ "$1" = "prune" ]; then
    :
else
    cat << EOF
    usage: $0 <init|show|create|prune>
EOF
fi
