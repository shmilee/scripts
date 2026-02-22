#!/bin/bash
# Copyright (C) 2020 shmilee
# EC version to run, 7.6.3, 7.6.7, 7.6.8

ResourcesDir=/usr/share/sangfor/EasyConnect/resources
# EC deb cache dir, extract dir
DATAREPO="${1:-/tmp/ECDATA}"
DATA_CLI="${2:-/tmp/ECDATA_CLI}"

download_extract() {
    VERSION=$1
    # deb url
    urlprefix='http://download.sangfor.com.cn/download/product/sslvpn/pkg'
    debfile="${DATAREPO}/EasyConnect_x64_v$VERSION.deb"
    if [ x"$VERSION" = x"7.6.3" ]; then
        deburl="$urlprefix/linux_01/EasyConnect_x64.deb"
    elif [ x"$VERSION" = x"7.6.7" ]; then
        deburl="$urlprefix/linux_767/EasyConnect_x64_7_6_7_3.deb"
    elif [ x"$VERSION" = x"7.6.8" ]; then
        urlprefix='https://github.com/shmilee/scripts/releases/download/v0.0.1'
        deburl="$urlprefix/easyconn_7.6.8.2-ubuntu_amd64.deb"
        debfile="${DATAREPO}/easyconn_7.6.8.2-ubuntu_amd64.deb"
    else
        echo ">> Not supported EC version: $VERSION"
        exit 1
    fi
    # download deb
    if [ ! -d "${DATAREPO}" ]; then
        mkdir -pv "${DATAREPO}"
    fi
    if [ ! -f "${debfile}" ]; then
        wget -c "${deburl}" -O "${debfile}"
    fi
    # extract deb
    rm -rf /tmp/ec-tmp
    mkdir /tmp/ec-tmp
    bsdtar -v -x -f "${debfile}" -C /tmp/ec-tmp
    bsdtar -v -x -f /tmp/ec-tmp/data.tar.?z -C /tmp/ec-tmp
}

add_common_data() {
    download_extract '7.6.8' # download & extract 7.6.8
    if [ ! -d "${DATA_CLI}" ]; then
        mkdir -pv "${DATA_CLI}"/resources/lib64
    fi
    for d in user_cert shell logs lang bin; do
        mv -v /tmp/ec-tmp/${ResourcesDir}/$d "${DATA_CLI}"/resources/$d
    done
    rm "${DATA_CLI}"/resources/bin/EasyMonitor
    for so in libnspr4.so libnss3.so libnssutil3.so libplc4.so libplds4.so libsmime3.so; do
        mv -v /tmp/ec-tmp/${ResourcesDir}/lib64/$so "${DATA_CLI}"/resources/lib64/$so
    done
    # conf -> conf-v7.6.8
    mv -v /tmp/ec-tmp/${ResourcesDir}/conf "${DATA_CLI}"/resources/conf-v7.6.8
}

add_other_conf() {
    if [ ! -d "${DATA_CLI}" ]; then
        mkdir -pv "${DATA_CLI}"/resources
    fi
    for ver in '7.6.3' '7.6.7'; do
        if [ ! -d "${DATA_CLI}"/resources/conf-v$ver ]; then
            download_extract $ver
            mv -v /tmp/ec-tmp/${ResourcesDir}/conf "${DATA_CLI}"/resources/conf-v$ver
        fi
    done
}

add_common_data
add_other_conf

old_PWD="$PWD"
cd "$DATA_CLI"

echo -e '7.6.3\n7.6.7\n7.6.8' > ./support_versions
cat >./change_authority.sh <<'EOF'
#!/bin/bash
ResourcesDir=/usr/share/sangfor/EasyConnect/resources
#文件权限处理
chmod +x ${ResourcesDir}/bin/easyconn
chmod +x ${ResourcesDir}/bin/ECAgent
chmod +x ${ResourcesDir}/bin/svpnservice
chmod +x ${ResourcesDir}/bin/CSClient
#保证logs文件夹存在
mkdir -p ${ResourcesDir}/logs
chmod 777 ${ResourcesDir}/logs
###CSClient创建的域套接字的句柄在这, 加写权限
chmod 777 ${ResourcesDir}/conf-v* -R
chmod +x ${ResourcesDir}/shell/*
#更改所有者
chown root:root ${ResourcesDir}/bin/ECAgent
chown root:root ${ResourcesDir}/bin/svpnservice
chown root:root ${ResourcesDir}/bin/CSClient
#添加s权限
chmod +s ${ResourcesDir}/bin/ECAgent
chmod +s ${ResourcesDir}/bin/svpnservice
chmod +s ${ResourcesDir}/bin/CSClient
EOF
chmod +x ./change_authority.sh

tar czvf "${old_PWD}"/easyconn_resources_x64_7.6-378.tar.gz ./

cd /tmp
rm -rf /tmp/ec-tmp
rm -r "$DATA_CLI"
