# nikola
# docker build --force-rm --no-cache --rm -t nikola .
FROM python:3.4.3-slim
MAINTAINER shmilee <shmilee.zju@gmail.com>

# python-nikola : requirements-extras.txt
# requests>=2.2.0
# Markdown>=2.4.0
# Jinja2>=2.7.2
# livereload==2.3.2
# pyphen>=0.9.1
# micawber>=0.3.0
# pygal==1.7.0
# typogrify>=2.0.4
# phpserialize>=1.3
# webassets>=0.10.1
# ipython[notebook]>=1.2.1
# ghp-import>=0.4.1
# pip install -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN useradd -m -g users -s /bin/bash -d /blog -u 1000 shmilee && \
    MIRROR='http://mirrors.tuna.tsinghua.edu.cn' && \
    echo "deb $MIRROR/debian/ jessie main non-free contrib" > /etc/apt/sources.list && \
    echo "deb $MIRROR/debian/ jessie-updates main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb $MIRROR/debian-security/ jessie/updates main non-free contrib" >> /etc/apt/sources.list && \
    apt-get update && \
    mkdeps='gcc g++ zlib1g-dev libxslt-dev' && \
    apt-get install -y \
		sqlite3 \
        libxslt1.1 \
		${mkdeps} \
        --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    nikola_extras='requests>=2.2.0 \
        Markdown>=2.4.0 \
        Jinja2>=2.7.2 \
        livereload==2.3.2 \
        pyphen>=0.9.1 \
        micawber>=0.3.0 \
        pygal==1.7.0 \
        typogrify>=2.0.4 \
        phpserialize>=1.3 \
        webassets>=0.10.1 \
        ipython[notebook]>=1.2.1' && \
    pip install nikola $nikola_extras && \
    find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-exec rm -rf '{}' + && \
    apt-get purge -y --auto-remove ${mkdeps} && \
    rm -rf /usr/share/{man/*,doc/*} /root/.cache/ /tmp/* && \
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d -not \( -name 'en_US' -o -name 'zh_CN' \) -exec rm -r {} \; && \
    touch /usr/share/locale/locale.alias && \
    rm -rf /usr/local/share/{man/*,doc/*}

#ENTRYPOINT ["nikola"]
#CMD ["help"]
