# nikola
# docker build --force-rm --no-cache --rm -t nikola . 
FROM arch:1505
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
#RUN pacman -Syu --noconfirm sqlite python-pip ipython ipython-notebook \
#    && pip install nikola requests markdown jinja2 webassets livereload micawber pygal typogrify phpserialize
RUN useradd -m -g users -G wheel -s /bin/bash -d /blog -u 1000 shmilee \
    && pacman -Syu --noconfirm python-nikola sqlite python-pip python-requests python-markdown python-jinja python-webassets livereload python-pygal python-typogrify\
    && pip install -i http://pypi.douban.com/simple --trusted-host pypi.douban.com micawber phpserialize \
    && pacman -Rsn --noconfirm python-pip && rm -rf /{root,tmp} \
    && rm -rf /usr/share/{man/*,doc/*,gtk-doc/} \
    && find /usr/lib/python3.4 \
		\( -type d -a -name test -o -name tests \) \
		-exec rm -rf '{}' + \
    && rm -r /var/cache/pacman/pkg/* \

#ENTRYPOINT ["nikola"]
#CMD ["help"]
