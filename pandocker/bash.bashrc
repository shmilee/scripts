# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

shopt -s extglob

# Load profiles from /etc/profile
test -r  /etc/profile && .  /etc/profile

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

export PROMPT_COMMAND='PS_result=`RET=$?;[ $RET == 0 ]&&echo -ne "\033[0;32m:) $RET"||echo -ne "\e[0;31m:( $RET"`'
PS1='(\A) \[\e[0;34m\]\u\[\e[0;0m\]@\[\e[0;33m\]\h\[\e[0;0m\] \w     $PS_result\[\e[0;0m\]\n\$ '

# ls
alias ls='ls -hF --color=auto'
alias lr='ls -r'   # recursive ls
alias ll='ls -l'
alias la='ll -A'
alias lz='ll -rS'  # sort by size
alias lt='ll -rt'  # sort by date
alias lm='la | more'
