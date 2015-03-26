#!/usr/bin/env bash

## zsh
## http://www.zsh.org/pub/zsh-${Ver}.tar.bz2
## depends=('pcre' 'libcap' 'gdbm')

Ver=5.0.7
file=./zsh-${Ver}.tar.bz2
file2=./oh-my-zsh.tar.gz

MYAPP=$HOME/myapp ## /usr

if [[ -n "$1" ]];then
    if [ $1 == extract -o $1 == e ]; then
        tar jxvf ${file}
    elif [ $1 == build -o $1 == b ]; then
        cd zsh-${Ver}/
        # Remove unneeded and conflicting completion scripts
	    for _fpath in AIX BSD Cygwin Darwin Debian Mandriva openSUSE Solaris; do
		    rm -rf Completion/$_fpath
		    sed "s#\s*Completion/$_fpath/\*/\*##g" -i Src/Zle/complete.mdd
	    done
	    rm -f  Completion/Linux/Command/_{pkgtool,rpmbuild,yast}
	    rm -f  Completion/Unix/Command/_{osc,systemd}

        ./configure --prefix=$MYAPP \
		    --docdir=$MYAPP/share/doc/zsh \
		    --htmldir=$MYAPP/share/doc/zsh/html \
		    --enable-maildir-support \
		    --with-term-lib='ncursesw' \
		    --enable-multibyte \
		    --enable-function-subdirs \
		    --enable-fndir=$MYAPP/share/zsh/functions \
		    --enable-scriptdir=$MYAPP/share/zsh/scripts \
		    --with-tcsetpgrp \
		    --enable-pcre \
		    --enable-cap \
		    --enable-zsh-secure-free || exit 1
        make || exit 2
    elif [ $1 == install -o $1 == i ]; then
        cd zsh-${Ver}/
        make install ||exit 3
    elif [ $1 == o ]; then
        echo "Install oh-my-zsh"
        tar -zxvf $file2 -C $MYAPP/share/
        echo "Done."
    else
        echo "Usage: $0 [extract|build|install|o]"
    fi
else
    echo "Usage: $0 [extract|build|install|o]"
fi
