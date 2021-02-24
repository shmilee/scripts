# 参考致谢
https://github.com/Hagb/docker-easyconnect

# build

```bash
tag=$(date +%y%m%d)
docker build --rm -t shmilee/easyconnect:$tag -f Dockerfile .
```

# run

## deb url

* [7.6.3](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb)
* [7.6.7](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb)

## deploy & start

```bash
./deploy.sh <ec version> <ec data repo>

./deploy.sh # default 7.6.3 ./ECDATA
./deploy.sh 7.6.7 $HOME/.ECDATA # example
```

```bash
path/to/ECrepo/ECdata_vVersion/start.sh <image tag> <params>

tag=210223
cd ./ECDATA/EasyConnect_x64_v7.6.3/

# 1. show help
./start.sh -h

# 2. default: enable danted port
./start.sh $tag -p 127.0.0.1:1080:1080

# 3. use VNC instead of X11
TYPE=VNC ./start.sh $tag -p 127.0.0.1:1080:1080 \
    -e TYPE=VNC -e PASSWORD=vncpasswd -p 5901:5901

# 4. disable danted, enable iptables, enable sshd
./start.sh $tag -e NODANTED=1 \
    -e IPTABLES=1 -e IPTABLES_LEGACY=1 \
    -e SSHD=1 -p 127.0.0.1:2222:22 -e ROOTPASSWD=w123q234
# 4. output
>>> Host Dir to mount: /home/xxxxx/ECDATA/EasyConnect_x64_v7.6.3
Start watching url.
non-network local connections being added to access control list
source hook_script.sh ...
Running hook main ...
Run hook_iptables
update-alternatives: using /usr/sbin/iptables-legacy to provide /usr/sbin/iptables (iptables) in manual mode
update-alternatives: using /usr/sbin/ip6tables-legacy to provide /usr/sbin/ip6tables (ip6tables) in manual mode
Run hook_sshd
mkdir: created directory '/run/sshd'
Run hook_fix763_login
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor 
Start EasyMonitor success!
Run CMD: /usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
(node:7) DeprecationWarning: Calling an asynchronous function without callback is deprecated.
(node:7) DeprecationWarning: Calling an asynchronous function without callback is deprecated.
[2021-02-24 02:28:48][E][  49][ 114][Register]cms client connect failed.
Starting CSClient svpnservice ...
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/CSClient 
Start CSClient success!
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/svpnservice -h /usr/share/sangfor/EasyConnect/resources/
Start svpnservice success!
(node:7) DeprecationWarning: Calling an asynchronous function without callback is deprecated.
(node:7) DeprecationWarning: Calling an asynchronous function without callback is deprecated.
non-network local connections being removed from access control list
Stop watching url.
```

```bash
cd
$HOME/.ECDATA/EasyConnect_x64_v7.6.7/start.sh $tag -p 3600:1080
# output
>>> Host Dir to mount: /home/xxx/.ECDATA/EasyConnect_x64_v7.6.7
Start watching url.
non-network local connections being added to access control list
source hook_script.sh ...
Running hook main ...
Run hook_danted
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor 
Start EasyMonitor success!
Run CMD: /usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
non-network local connections being removed from access control list
Stop watching url.
```

## issues

1. EasyConnect, 在登陆后产生一到两个僵尸进程, 所以镜像中最好包含 `tini`.
   `ps -A -ostat,ppid | grep -e '[zZ]'| awk '{ print $2 }' | uniq | xargs ps -p`
2. Host 浏览器未设置EC代理时, 打开 EC 相关 URL 卡圈.
