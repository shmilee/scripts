# debian 10 buster
# https://hub.docker.com/_/debian/

FROM debian:buster-slim

LABEL maintainer="shmilee.zju@gmail.com" \
      release.version="buster" \
      ec.versions="7.6.3 7.6.7 etc." \
      description="buster with EasyConnect run prerequisites"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    DEBIAN_CODENAME=buster \
    DEBIAN_MIRROR=http://mirrors.163.com/debian \
    EasyConnectDir=/usr/share/sangfor/EasyConnect

#    DEBIAN_SECURITY_MIRROR=http://mirrors.163.com/debian-security \
#    && echo "deb $DEBIAN_SECURITY_MIRROR $DEBIAN_CODENAME/updates main contrib" >> /etc/apt/sources.list \

COPY dpkg.cfg.excludes /etc/dpkg/dpkg.cfg.d/01_excludes
RUN echo "deb $DEBIAN_MIRROR $DEBIAN_CODENAME main contrib" > /etc/apt/sources.list \
    && echo "deb $DEBIAN_MIRROR $DEBIAN_CODENAME-updates main contrib" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        tini busybox iptables iproute2 psmisc \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 \
        dante-server openssh-client openssh-server \
        ttf-wqy-microhei \
    && rm /usr/bin/tini-static \
    && rm -r /usr/share/icons/Adwaita/ \
    && ln -s "$(which busybox)" /usr/local/bin/ip \
    && ln -s "$(which busybox)" /usr/local/bin/ifconfig \
    && ln -s "$(which busybox)" /usr/local/bin/route \
    && ln -s "$(which busybox)" /usr/local/bin/ping \
    && apt-get -y autoremove && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD ./easyconnect.sh /usr/bin/easyconnect.sh
RUN chmod +x /usr/bin/easyconnect.sh

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["easyconnect.sh", "2"]
