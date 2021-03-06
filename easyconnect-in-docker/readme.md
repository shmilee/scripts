# 参考致谢
https://github.com/Hagb/docker-easyconnect

# build or pull

```bash
export TAG=$(date +%y%m%d)
docker build --rm -t shmilee/easyconnect:$TAG -f Dockerfile .
```

```bash
export TAG=210306
docker pull shmilee/easyconnect:$TAG
```

# run

## package files

* [7.6.3](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb)
* [7.6.7](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb)
* [7.6.8 CLI](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)
  extract cli data files for `7.6.3`, `7.6.7`

## deploy

```bash
./deploy.sh <ec version> <ec data repo>

./deploy.sh # default 7.6.3 ./ECDATA

./deploy.sh 7.6.3 $HOME/.ECDATA # example
./deploy.sh 7.6.7 $HOME/.ECDATA
./slim_ecdata.sh 7.6.3 7.6.7 $HOME/.ECDATA # ln file 3 <- 7 if md5 equal
```

## start 7.6.3

```bash
TAG=<image tag> USEUI=<X11,VNC,CLI> path/to/ECrepo/ECdata_vVersion/start.sh <params>

cd ./ECDATA/EasyConnect_x64_v7.6.3/

# 1. show help, default: TAG=210306 USEUI=X11
./start.sh -h

# 2. default: use X11, enable danted port
./start.sh -p 127.0.0.1:1080:1080

# 3. use VNC instead of X11
USEUI=VNC ./start.sh -p 127.0.0.1:1080:1080 \
    -e PASSWORD=vncpasswd -p 5901:5901

# 4. disable danted, enable iptables, enable sshd
./start.sh -e NODANTED=1 \
    -e IPTABLES=1 -e IPTABLES_LEGACY=1 \
    -e SSHD=1 -p 127.0.0.1:2222:22 -e ROOTPASSWD=w123q234
# 4. output
>>> Host Dir to mount: /home/xxxxx/ECDATA/EasyConnect_x64_v7.6.3
Start watching url.
non-network local connections being added to access control list
source hook_script.sh ...
Running hook main ...
Run hook_resources_bin
removed '/usr/share/sangfor/EasyConnect/resources/bin'
'/usr/share/sangfor/EasyConnect/resources/bin' -> 'bin-orig'
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

## start 7.6.7

```bash
TAG=210306 USEUI=X11 $HOME/.ECDATA/EasyConnect_x64_v7.6.7/start.sh -p 3600:1080
# output
>>> Host Dir to mount: /home/xxx/.ECDATA/EasyConnect_x64_v7.6.7
Start watching url.
non-network local connections being added to access control list
source hook_script.sh ...
Running hook main ...
Run hook_resources_bin
removed '/usr/share/sangfor/EasyConnect/resources/bin'
'/usr/share/sangfor/EasyConnect/resources/bin' -> 'bin-orig'
Run hook_danted
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor 
Start EasyMonitor success!
Run CMD: /usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
non-network local connections being removed from access control list
Stop watching url.
```

* cli login

```bash
USEUI=CLI $HOME/.ECDATA/EasyConnect_x64_v7.6.7/start.sh -p 3600:1080
# output
>>> Host Dir to mount: /home/xxx/.ECDATA/EasyConnect_cli_x64_v7.6.8
source hook_script.sh ...
Running hook main ...
Run hook_resources_bin
removed '/usr/share/sangfor/EasyConnect/resources/bin'
'/usr/share/sangfor/EasyConnect/resources/bin' -> 'bin-cli768'
>> /usr/share/sangfor/EasyConnect/resources/bin/ECAgent not -u -g
>> /usr/share/sangfor/EasyConnect/resources/bin/svpnservice not -u -g
>> /usr/share/sangfor/EasyConnect/resources/bin/CSClient not -u -g
Run hook_danted
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor 
Start EasyMonitor success!
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/easyconn login -v
No previous user logged in!
No previous user logged in!
vpn adress: vpn.xxx.cn:443
Get https://vpn.xxx.cn:443/por/login_auth.csp ...
Get https://vpn.xxx.cn:443/por/login_auth.csp Done, code=200
Cipher Suite: AES128-SHA
Begin detect listen port of ECAgent ...
Read listen port of ECAgent from file: 54530
Done detect listen port of ECAgent, result: 54530!
Get https://127.0.0.1:54530/ECAgent ...
Get https://127.0.0.1:54530/ECAgent Done, code=200
username: xxxx
password: xxxx
Authenticating user "xxxx" by password ...
Post https://vpn.xxx.cn:443/por/login_psw.csp ...
Post https://vpn.xxx.cn:443/por/login_psw.csp Done, code=200
Get https://127.0.0.1:54530/ECAgent ...
Get https://127.0.0.1:54530/ECAgent Done, code=200
Get https://127.0.0.1:54530/ECAgent ...
Get https://127.0.0.1:54530/ECAgent Done, code=200
user "xxxx" login successfully!
 -> Enter 'XXX' to exit:XXX
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/easyconn logout
user "xxxx" is already logged out!
```

## desktop file

* edit `Exec` options in `ec-7.6.x.desktop`

```bash
ls .ECDATA/
# output
easyconn_7.6.8.2-ubuntu_amd64.deb  EasyConnect_x64_v7.6.3.deb  EasyConnect_x64_v7.6.7.deb  ec-7.6.7.desktop
EasyConnect_x64_v7.6.3             EasyConnect_x64_v7.6.7      ec-7.6.3.desktop

du -d2 -h .ECDATA/
# output
421K    .ECDATA/EasyConnect_x64_v7.6.3/locales
46M     .ECDATA/EasyConnect_x64_v7.6.3/resources
168M    .ECDATA/EasyConnect_x64_v7.6.3
421K    .ECDATA/EasyConnect_x64_v7.6.7/locales
19M     .ECDATA/EasyConnect_x64_v7.6.7/resources
20M     .ECDATA/EasyConnect_x64_v7.6.7
317M    .ECDATA/
```

## issues

1. EasyConnect, 在登陆后产生一到两个僵尸进程, 所以镜像中最好包含 `tini`.
   `ps -A -ostat,ppid | grep -e '[zZ]'| awk '{ print $2 }' | uniq | xargs ps -p`
2. Host 浏览器未设置EC代理时, 打开 EC 相关 URL 卡圈.
