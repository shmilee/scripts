#!/bin/bash
# Copyright (C) 2025 shmilee

SSH_USER=root
SSH_HOST=${1:-node32}
SSH_CMD=ssh
SCP_CMD=scp

backup(){
    $SSH_CMD ${SSH_USER}@${SSH_HOST} "tar czvf /etc/passwd-$(date +%F-%H%M%S).tar.gz /etc/{group,group-,passwd,passwd-,gshadow,gshadow-,shadow,shadow-}"
    $SSH_CMD ${SSH_USER}@${SSH_HOST} "ls -lh /etc/passwd-*.tar.gz"
}

scp_mod(){
    local mod=$1
    for f in "${@:2}"; do
        echo "****** $f ******"
        $SCP_CMD /etc/$f ${SSH_USER}@${SSH_HOST}:/etc/$f
        $SSH_CMD ${SSH_USER}@${SSH_HOST} "chmod $mod /etc/$f; ls -lh /etc/$f"
        echo
    done
}

if $SSH_CMD ${SSH_USER}@${SSH_HOST} whoami >/dev/null; then
    echo -e "\n==> $SSH_HOST Start.\n"
    backup
    scp_mod 644 group group- passwd passwd-
    scp_mod 000 gshadow gshadow- shadow shadow-
    echo -e "\n==> $SSH_HOST Done.\n"
else
    echo -e "\n==> $SSH_HOST Skip/lost?!\n"
fi
