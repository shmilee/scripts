# 参考致谢

* https://github.com/docker-easyconnect/docker-easyconnect
* https://github.com/Hagb/docker-easyconnect

# build image

```bash
export TAG=$(date +%y%m%d)
docker build --rm -t shmilee/sangfor:$TAG -f Dockerfile .
```

```bash
$ docker images
IMAGE                           ID             DISK USAGE
debian:bookworm-20260202-slim   91c6d3bae450       74.8MB   
shmilee/sangfor:260911          ca135810cb13        611MB
```

# run

## package files

* [EasyConnect 7.6.3](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb)
* [EasyConnect 7.6.7](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb)
* [EasyConnect 7.6.8 CLI](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)
  extract cli data files for `7.6.3`, `7.6.7`

* [aTrust 2.5.16.20](https://atrustcdn.sangfor.com/standard/linux/2.5.16.20/uos/amd64/aTrustInstaller_amd64.deb)

* [TopSAP 3.6.3.17.2](https://app.topsec.com.cn/linux/general/x86_64/deb/TopSAP-3.6.3.17.2-x86_64.deb)

## deploy

```bash
./ec-deploy.sh <EasyConnect-version> <sangfor-dataDir>
./ec-deploy.sh # default 7.6.3 to ./sangfor
./ec-deploy.sh 7.6.3 $HOME/.sangfor # example
./ec-deploy.sh 7.6.7 $HOME/.sangfor
./ec-slimdata.sh 7.6.3 7.6.7 $HOME/.sangfor # ln file 3 <- 7 if md5 equal

./at-deploy.sh <aTrust-version> <sangfor-dataDir>
./at-deploy.sh 2.5.16.20 ~/.sangfor

./ts-deploy.sh <TopSAP-version> <sangfor-dataDir>
./ts-deploy.sh 3.6.3.17.2 ~/.sangfor
```

## start aTrust 2.5.16.20

* Only UI=X11,VNC supported for aTrust.

```bash
TAG=<image tag> UI=<X11,VNC> SHOSTNAME=newname SMACADDR=aa:bb:cc:dd:ee:ff \
    ~/.sangfor/aTrust_amd64_v2.5.16.20/start.sh --help <params>

cd ~/.sangfor/aTrust_amd64_v2.5.16.20/

# 1. show help, default: TAG=260911 UI=X11
./start.sh -h

# 2. default: use X11, enable danted port
./start.sh -p 127.0.0.1:1080:1080

# 3. use VNC instead of X11
UI=VNC ./start.sh -p 127.0.0.1:1080:1080 \
    -e PASSWORD=vncpasswd -p 5901:5901

# 4. disable danted, enable iptables, enable sshd
./start.sh -e NODANTED=1 \
    -e IPTABLES=1 -e IPTABLES_LEGACY=1 \
    -e SSHD=1 -p 127.0.0.1:2222:22 -e ROOTPASSWD=w123q234
```

## start EasyConnect 7.6.3 or 7.6.7

* UI=X11,VNC in new image `shmilee/sangfor:260911`, get `Segmentation fault (core dumped)`.
* Only CLI login supported in new image.
* Old UI=X11,VNC support needs old image `shmilee/easyconnect:210306` and `start.sh, hook_script.sh`.

```bash
UI=CLI $HOME/.sangfor/EasyConnect_x64_v7.6.7/start.sh -p 3600:1080
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
==> WARNING: Please run 'clear' to hide you password!!!
╭─[root@8ec67df00663]-(22:51:45)
╰─[Enter login/logout/mylogin/bash/exit/??]
╭─[root@8ec67df00663]-[tun0:10.xxx.1.xxx]-(22:51:48)
╰─[Enter login/logout/mylogin/bash/exit/??] history
==> Run: history
    1  history
╭─[root@8ec67df00663]-[tun0:10.xxx.1.xxx]-(22:51:51)
╰─[Enter login/logout/mylogin/bash/exit/??] exit
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/easyconn logout
user "xxxx" is already logged out!
```

## start TopSAP 3.6.3.17.2

* TopSAP 3.6.3.17.2 **无 CLI 登录**，只能 GUI：`UI=X11`（转发宿主显示）或 `UI=VNC`。
* 挂载固定 `product_uuid` 到 `/sys/class/dmi/id/product_uuid`，保证机器标识稳定。
* 流程：`sv_websrv`(127.0.0.1:7443) + GUI → 用户登录 → `tun0`(mtu 1300 + MASQUERADE) → danted socks5 :1080。
* `SHOSTNAME SMACADDR TOPUUID` 三个变量可通过 env.conf 设置，`start.sh` 会自动读取。

```bash
cd ~/.sangfor/TopSAP_x64_v3.6.3.17.2/

# 1. show help
./start.sh -h

# 2. default: X11 + danted socks5 proxy   (TAG = 你构建镜像用的 tag)
TAG=260911 UI=X11 ./start.sh -p 127.0.0.1:1080:1080

# 3. VNC instead of X11
TAG=260911 UI=VNC ./start.sh -e PASSWORD=vncpasswd \
    -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080

# 4. iptables full routing (disable danted)
TAG=260911 UI=X11 ./start.sh -e IPTABLES=1 -e NODANTED=1

# 5. custom product_uuid
TAG=260911 UI=X11 TOPUUID=xxxx-xxxx ./start.sh -p 127.0.0.1:1080:1080
```

## desktop file

* edit `Exec` options in `ec-7.6.x.desktop`, `at-example.desktop`

```bash
$ ls ~/.sangfor/
at-2.5.16.20.desktop         atrust-root-data                   EasyConnect_x64_v7.6.3.deb  ec-7.6.3.desktop
aTrust_amd64_v2.5.16.20      easyconn_7.6.8.2-ubuntu_amd64.deb  EasyConnect_x64_v7.6.7      ec-7.6.7.desktop
aTrust_amd64_v2.5.16.20.deb  EasyConnect_x64_v7.6.3             EasyConnect_x64_v7.6.7.deb

$ du -d1 -h ~/.sangfor/
178M	~/.sangfor/EasyConnect_x64_v7.6.3
55M	    ~/.sangfor/EasyConnect_x64_v7.6.7
553M	~/.sangfor/aTrust_amd64_v2.5.16.20
4.0M	~/.sangfor/atrust-root-data
1.1G	~/.sangfor/
1.1G	总计
```

## issues

1. EasyConnect, 在登陆后产生一到两个僵尸进程, 所以镜像中最好包含 `tini`.
   `ps -A -ostat,ppid | grep -e '[zZ]'| awk '{ print $2 }' | uniq | xargs ps -p`
2. Host 浏览器未设置EC代理时, 打开 EC 相关 URL 卡圈.
3. 舍弃 EasyConnect GUI 使用方式。
4. TopSAP 3.6.3.17.2 无 CLI 登录, 只能 GUI (X11/VNC). GUI 需 `--disable-gpu --disable-dev-shm-usage`,
   否则 docker 内 GPU 进程初始化偶发 `Trace/breakpoint trap (SIGTRAP)` 崩溃.
5. TopSAP 登录页对 `https://localhost:7443/api/v1/*` 发请求, 由 `sv_websrv` 服务; 登录成功后才建 `tun0`.
   `sv_websrv` 用顶层 `/opt/TopSAP/sv_websrv`（cwd=/opt/TopSAP）, 与 GUI 共享 `/tmp/TopSAP_ELE/.BUFF`.
6. TopSAP 用 `/sys/class/dmi/id/product_uuid` 作机器唯一标识, 多设备登录同一账号可能被服务端禁用,
   故 `start.sh` 挂载固定 UUID（可用 `TOPUUID=` 覆盖）.

