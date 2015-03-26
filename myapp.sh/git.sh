#!/usr/bin/env bash

## git
## https://www.kernel.org/pub/software/scm/git/git-$Ver.tar.xz
## depends=('curl' 'expat>=2.0' 'perl-error' 'perl>=5.14.0' 'openssl' 'pcre')
## makedepends=('python2' 'libgnome-keyring' 'xmlto' 'asciidoc')

Ver=2.3.1
file=./git-${Ver}.tar

MYAPP=$HOME/myapp ## /usr
CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe --param=ssp-buffer-size=4"
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro"

export PYTHON_PATH='/usr/bin/python2'

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar xvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd git-${Ver}/
        make prefix=$MYAPP gitexecdir=$MYAPP/lib/git-core \
            CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
            USE_LIBPCRE=1 \
            NO_CROSS_DIRECTORY_HARDLINKS=1 \
            MAN_BOLD_LITERAL=1 \
            all || exit 1
        make -C contrib/credential/gnome-keyring || exit 2
        make -C contrib/subtree prefix=$MYAPP gitexecdir=$MYAPP/lib/git-core all ||exit 3
    elif [ $1 == install -o $1 == i ]; then
        cd git-${Ver}/
        make prefix=$MYAPP gitexecdir=$MYAPP/lib/git-core \
            CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
            USE_LIBPCRE=1 \
            NO_CROSS_DIRECTORY_HARDLINKS=1 \
            MAN_BOLD_LITERAL=1 \
            INSTALLDIRS=vendor install || exit 4
        # fancy git prompt
        install -Dm644 ./contrib/completion/git-prompt.sh $MYAPP/share/git/git-prompt.sh
        # gnome credentials helper
        install -m755 contrib/credential/gnome-keyring/git-credential-gnome-keyring \
            $MYAPP/lib/git-core/git-credential-gnome-keyring
        make -C contrib/credential/gnome-keyring clean
        # subtree installation
        make -C contrib/subtree prefix=$MYAPP gitexecdir=$MYAPP/lib/git-core install
        # the rest of the contrib stuff
        cp -a ./contrib/* $MYAPP/share/git/
        # scripts are for python 2.x
        sed -i 's|#![ ]*/usr/bin/env python$|#!/usr/bin/env python2|' \
          $(find "$MYAPP" -name '*.py') \
          $MYAPP/share/git/gitview/gitview \
          $MYAPP/share/git/remote-helpers/git-remote-bzr \
          $MYAPP/share/git/remote-helpers/git-remote-hg
        sed -i 's|#![ ]*/usr/bin/python$|#!/usr/bin/python2|' \
          $MYAPP/share/git/svn-fe/svnrdump_sim.py

        # remove perllocal.pod, .packlist, and empty directories.
        rm -rf $MYAPP/lib/perl5

    else
        echo "Usage: $0 [extract|build|install]"
    fi
else
    echo "Usage: $0 [extract|build|install]"
fi
