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

# User specific aliases and functions

# source /public/program/pgi/linux86-64/10.0/pgi.sh
# source /public/program/pgi.7.0/linux86-64/7.1-4/pgi.sh

# intel mpi 64bit
# source /public/program/intel/impi/3.2.1.009/bin64/mpivars.sh

# intel mpi
# source /public/program/intel/impi/3.2.1.009/bin/mpivars.sh

# 2_1.3.2p1+gcc
# source /public/program/mpi/mpich2/1.3.2p1/bin/mpivars.sh

# mpich2_1.4.1p1+gcc
# source /public/program/mpi/mpich2/1.4.1p1/gcc.gfortran/bin/mpivars.sh

# openmpi+icc
source  /public/program/mpi/openmpi/1.4.3/icc_ifort/bin/mpivars.sh

# openmpi+gcc
# source /public/program/mpi/openmpi/1.4.3/gcc.gfortran/bin/mpivars.sh

# mvapich2+icc
# source /public/program/mpi/mvapich2/1.4.1/icc.ifort/x86_64/bin/mpivars.sh

# LD_LIBRARY_PATH=/public/program/hdf5-1.8.8-linux-x86_64-static/lib:${LD_LIBRARY_PATH}
# export LD_LIBRARY_PATH

LD_LIBRARY_PATH=~/myapp/usr/lib:${LD_LIBRARY_PATH}
PATH=~/myapp/usr/bin:$PATH

