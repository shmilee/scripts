#
# ~/.bashrc
#

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi


# If not running interactively, don't do anything
shopt -s extglob
[[ $- != *i* ]] && return

# colorful man page
export PAGER="`which less` -s"
export BROWSER="$PAGER"
export LESS_TERMCAP_mb=$'\E[01;34m'
export LESS_TERMCAP_md=$'\E[01;34m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;33m'

# PS1
export PROMPT_COMMAND='PS_result=`RET=$?;[ $RET == 0 ]&&echo -ne "\033[0;32m:) $RET"||echo -ne "\e[0;31m:( $RET"`'
PS1='(\A) \[\e[0;34m\]\u\[\e[0;0m\]@\[\e[0;33m\]\h\[\e[0;0m\] \w     $PS_result\[\e[0;0m\]\n\$ '

# modified commands
alias grep='grep --color=auto'
alias more='less'
alias c='clear'
alias df='df -h'
alias du='du -c -h'
alias openports='netstat --all --numeric --programs --inet --inet6'
alias ping='ping -c 5'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

# ls
alias ls='ls -hF --color=auto'
alias lr='ls -R'                    # recursive ls
alias ll='ls -l'
alias la='ll -A'
alias lx='ll -BX'                   # sort by extension
alias lz='ll -rS'                   # sort by size
alias lt='ll -rt'                   # sort by date
alias lm='la | more'

# safety features
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'                    # 'rm -i' prompts for every file
alias ln='ln -i'
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# IFTS.ZJU
alias ifts="TERM=linux ssh -p 5789 smli@10.22.92.173"     
alias oldifts="TERM=linux ssh -p 10321 smli@10.22.92.172"

scp2ifts () { scp -P 5789 -r $1 smli@10.22.92.173:upload/; }
scp4ifts () { scp -P 5789 -r smli@10.22.92.173:$1 ./; }

# ArchLinux
source /usr/share/doc/pkgfile/command-not-found.bash

alias Arch_update='sudo pacman -Syu'
alias fbterm_zh='LANG=zh_CN.UTF-8 fbterm'

extract() {
    local c e i
    (($#)) || return
    for i; do
        c=''
        e=1
        if [[ ! -r $i ]]; then
            echo "$0: file is unreadable: \`$i'" >&2
            continue
        fi
        case $i in
        *.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz)))))
               c='bsdtar xvf';;
        *.7z)  c='7z x';;
        *.Z)   c='uncompress';;
        *.bz2) c='bunzip2';;
        *.exe) c='cabextract';;
        *.gz)  c='gunzip';;
        *.rar) c='unrar x';;
        *.xz)  c='unxz';;
        *.zip) c='unzip -O GBK';;
        *)     echo "$0: unrecognized file extension: \`$i'" >&2
               continue;;
        esac
        command $c "$i"
        e=$?
    done
    return $e
}

# list "${@:3}", $1 beginning number, $2 the number of items in a row
list() {
    local n=($(seq -w $1 $((${#@}+$1-3)))) i=0 _f
    for _f in ${@:3}; do
        (($i%$2==0)) && echo -e -n "\t" # indent
        echo -e -n "${n[$i]}) $_f;\t"
        (( $i%$2 == $(($2-1)) )) && echo # \n
        ((i++))
    done
    (($i%$2==0)) ||echo # aliquant \n
}

# simplified systemd command, for instance "sudo systemctl stop xxx.service" - > "0.stop xxx"
if ! systemd-notify --booted;
then  # for not systemd
    0.start() {
        sudo rc.d start $@
    }

    0.restart() {
        sudo rc.d restart $@
    }

    0.stop() {
        sudo rc.d stop $@
    }
else
# start systemd service
    0.start() {
        sudo systemctl start $@
    }
# restart systemd service
    0.restart() {
        sudo systemctl restart $@
    }
# stop systemd service
    0.stop() {
        sudo systemctl stop $@
    }
# enable systemd service
    0.enable() {
        sudo systemctl enable $@
    }
# disable a systemd service
    0.disable() {
        sudo systemctl disable $@
    }
# show the status of a service
    0.status() {
        systemctl status $@
    }
# reload a service configuration
    0.reload() {
        sudo systemctl reload $@
    }
# list all running service
    0.list() {
        systemctl
    }
# list all failed service
    0.failed () {
        systemctl --failed
    }
# list all systemd available unit files
    0.list-files() {
        systemctl list-unit-files
    }
# check the log
    0.log() {
        sudo journalctl $@
    }
# show wants
    0.wants() {
        systemctl show -p "Wants" $1.target
    }
# analyze the system
    0.analyze() {
        systemd-analyze $@
    }
fi

