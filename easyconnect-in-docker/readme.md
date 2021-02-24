# 参考
https://github.com/Hagb/docker-easyconnect

# build

```bash
tag=$(date +%y%m%d)
docker build --rm -t shmilee/easyconnect:$tag -f Dockerfile .
```

# run

## deb url
[7.6.3](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb)
[7.6.7](http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb)

## deploy & start

```bash
./deploy.sh <ec version> <ec data repo>

./deploy.sh # default 7.6.3 ./ECDATA
./deploy.sh 7.6.7 $HOME/.ECDATA # example
```

```bash
tag=210223
cd ./ECDATA/EasyConnect_x64_v7.6.3/
# show help
./start.sh -h
# default: enable danted port
./start.sh $tag -p 127.0.0.1:1080:1080
# use VNC instead of X11
TYPE=VNC ./start.sh $tag -p 127.0.0.1:1080:1080 \
    -e TYPE=VNC -e PASSWORD=vncpasswd -p 5901:5901
# disable danted, enable iptables, enable sshd
./start.sh $tag -e NODANTED=1 \
    -e IPTABLES=1 -e IPTABLES_LEGACY=1 \
    -e SSHD=1 -p 127.0.0.1:2222:22 -e ROOTPASSWD=w123q234

cd
$HOME/.ECDATA/EasyConnect_x64_v7.6.7/start.sh $tag -p 3600:1080
```
