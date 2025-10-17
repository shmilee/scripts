# docker build --force-rm --no-cache --rm -t shmilee/moontv:$(date +%y%m%d) .
#
# 1. run as user 'node', uid=1000. chown of ./moontv-app
# 2. about squashfuse: https://github.com/gliderlabs/docker-alpine/issues/268
# docker run --name moontv --detach -p 3000:3000 \
#   --user node --device /dev/fuse --privileged \
#   --env-file ./moontv-app/env-file -v ./moontv-app:/moontv-app

FROM node:24.8.0-alpine3.22

LABEL maintainer="shmilee <shmilee.zju@gmail.com>" version="1.0"

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    TIMEZONE=Asia/Shanghai \
    TERM=xterm-color

RUN echo https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.22/main > /etc/apk/repositories \
 && echo https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.22/community >> /etc/apk/repositories \
 && echo "==> add tini bash squashfuse valkey ..." \
 && apk --no-cache add tini coreutils bash iproute2 \
        ca-certificates ca-certificates-bundle \
        squashfuse fuse3 procps-ng valkey valkey-cli curl tzdata \
 && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 && apk --no-cache del tzdata

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/moontv-app/moontv-start.sh", "v100"]
