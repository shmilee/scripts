# debian 12 Bookworm 2023-06-10 2026-06-10 2028-06-30
# https://www.debian.org/releases/index.en.html
# https://hub.docker.com/_/debian/

FROM debian:bookworm-slim

LABEL maintainer="shmilee.zju@gmail.com" \
      release.version="bookworm" \
      ec.versions="7.6.3, 7.6.7 etc." \
      at.versions="2.4.10.50, 2.5.16.20 etc." \
      description="Bookworm with EasyConnect & aTrust run prerequisites"

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    DEBIAN_CODENAME=bookworm \
    DEBIAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/debian/

COPY dpkg.cfg.excludes /etc/dpkg/dpkg.cfg.d/01_excludes
COPY docker-root-usr /usr
RUN apt-get update \
    && apt-get install -y apt-transport-https ca-certificates \
    && echo "deb $DEBIAN_MIRROR $DEBIAN_CODENAME main contrib non-free non-free-firmware" > /etc/apt/sources.list \
    && echo "deb $DEBIAN_MIRROR $DEBIAN_CODENAME-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list \
    && echo "deb $DEBIAN_MIRROR $DEBIAN_CODENAME-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list \
    && apt-get update \
    && echo "Add packages for EasyConnect" \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        tini busybox iptables iproute2 psmisc procps \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 \
        dante-server openssh-client openssh-server \
        fonts-wqy-microhei \
    && echo "Add extra packages for aTrust" \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        libatk-bridge2.0-0 libgtk-3-0 libgbm1 libqt5x11extras5 libxss1 \
        libqt5core5a libqt5network5 libqt5widgets5 \
    && rm /usr/bin/tini-static \
    && rm -r /usr/share/icons/Adwaita/ \
    && ln -s "$(which busybox)" /usr/local/bin/ip \
    && ln -s "$(which busybox)" /usr/local/bin/ifconfig \
    && ln -s "$(which busybox)" /usr/local/bin/route \
    && ln -s "$(which busybox)" /usr/local/bin/ping \
    && apt-get -y autoremove && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mv /usr/sbin/sysctl /usr/sbin/sysctl.real \
    && ln -s /usr/sbin/sysctl-hook /usr/sbin/sysctl \
    && mv /usr/bin/loginctl /usr/bin/loginctl.real \
    && ln -s /usr/bin/loginctl.fake /usr/bin/loginctl \
    && chmod +x /usr/bin/sangfor.sh /usr/sbin/sysctl-hook /usr/bin/loginctl.fake

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["sangfor.sh", "2"]
