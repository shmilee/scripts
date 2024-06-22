# 参考致谢
https://github.com/Hagb/docker-easyconnect

# build

* [7.6.3](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb)
* [7.6.7](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb)
* [7.6.8](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)

```bash
./get_cli_resources.sh
export TAG=$(date +%y%m%d)
docker build --rm -t shmilee/easyconnect-cli:$TAG -f Dockerfile.cli .
```

```
$ dockre images
REPOSITORY                TAG              IMAGE ID       CREATED         SIZE
shmilee/easyconnect-cli   210307           b85eb30e8d2a   9 minutes ago   106MB
```

# run

```bash
docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -i -t \
    -p 127.0.0.1:3600:1080 \
    -e ECADDRESS=xxx.cn:443 \
    -e ECUSER=xxx \
    -e VERSION=7.6.7 \
    shmilee/easyconnect-cli:$TAG
# output
Running default main ...
Run hook_resources_conf
'/usr/share/sangfor/EasyConnect/resources/conf' -> 'conf-v7.6.7'
Run hook_danted
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/ECAgent --resume &
Start ECAgent success!
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/easyconn login -v -d xxx:443 -u xxx
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
password: xxxx
Authenticating user "xxxx" by password ...
Post https://vpn.xxx.cn:443/por/login_psw.csp ...
Post https://vpn.xxx.cn:443/por/login_psw.csp Done, code=200
Get https://127.0.0.1:54530/ECAgent ...
Get https://127.0.0.1:54530/ECAgent Done, code=200
Get https://127.0.0.1:54530/ECAgent ...
Get https://127.0.0.1:54530/ECAgent Done, code=200
user "xxx" login successfully!
==> WARNING: Please run 'clear' to hide you password!!!
╭─[root@8ec67df00663]-(22:51:45)
╰─[Enter login/logout/mylogin/bash/exit/??]
╭─[root@8ec67df00663]-[tun0:10.xxx.1.xxx]-(22:51:51)
╰─[Enter login/logout/mylogin/bash/exit/??] exit
Run CMD: /usr/share/sangfor/EasyConnect/resources/bin/easyconn logout
user "xxx" is already logged out!
```
