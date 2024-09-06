#!/bin/bash
# Copyright (C) 2024 shmilee

CMD='rsync_tmbackup.sh'
PROFILE="$1"
Exclude_List=

if (hash rsync &>/dev/null) && (hash ${CMD} &>/dev/null); then
    if [ -z "${PROFILE}" ]; then
        echo "usage: $0 <path/to/profile>"
        exit 1
    fi
    if [ ! -f "${PROFILE}" ]; then
        echo "!!! Profile not found: ${PROFILE} !"
        exit 2
    fi
else
    echo "!!! Lost command: rsync or ${CMD}!"
    exit 3
fi

read_profile() {
    local lineN0=$(awk '/THE_EXCLUDE_LIST_BEGIN/{print NR;exit}' "${PROFILE}")
    local lineN1=$(awk '/^[ ]*THE_EXCLUDE_LIST_BEGIN[ ]*$/{print NR;exit}' "${PROFILE}")
    local lineN2=$(awk '/^[ ]*THE_EXCLUDE_LIST_END[ ]*$/{print NR;exit}' "${PROFILE}")
    if [ -z "$lineN0" -o -z "$lineN1" -o -z "$lineN2" ]; then
        echo "!!! Invalid profile: ${PROFILE} !"
        exit 4
    fi
    local profile_source_part="$(mktemp -u -t 'atb.profile.source.part.XXXXX')"
    awk -v n=$lineN0 '{if(NR<n){print $0}}' "${PROFILE}" >"${profile_source_part}"
    Exclude_List="$(mktemp -u -t 'atb.profile.exclude.list.XXXXX')"
    awk -v n1=$lineN1 -v n2=$lineN2 '{if((n1<NR)&&(NR<n2)){print $0}}' "${PROFILE}" >"${Exclude_List}"

    source "${profile_source_part}"
    rm "${profile_source_part}"
    # default
    RSYNC_FLAGS="${RSYNC_FLAGS:-$($CMD --rsync-get-flags)}"
    EXP_STATEGY="${EXP_STATEGY:-1:1 30:7 365:30}"
}


show_info() {
    cat <<EOF

    SSH_PORT     = ${SSH_PORT}
    SSH_KEY      = ${SSH_KEY}
    SOURCE       = ${SOURCE}
    DESTINATION  = ${DESTINATION}
    RSYNC_FLAGS  = ${RSYNC_FLAGS}
    EXP_STATEGY  = ${EXP_STATEGY}
    Exclude_List = ${Exclude_List}

EOF
}

ask() {
    local msg=$1 ans
    read -p "==> $msg [y/n] " ans
    if [ "$ans" = 'y' -o "$ans" = 'Y' ];then
        return 0
    else
        return 1
    fi
}

create_backup() {
    local SSHOPT=''
    if [ -n "${SSH_PORT}" ]; then
        SSHOPT+="-p ${SSH_PORT}"
    fi
    if [ -n "${SSH_KEY}" ]; then
        SSHOPT+=" -i ${SSH_KEY}"
    fi
    printf 'CMD: %s %s --rsync-set-flags "%s" --strategy "%s" "%s" "%s" "%s"\n\n' \
        "${CMD}" "${SSHOPT}" "${RSYNC_FLAGS}" "${EXP_STATEGY}" \
        "${SOURCE}" "${DESTINATION}" "${Exclude_List}"
    if ask "Continue?"; then
        ${CMD} ${SSHOPT} --rsync-set-flags "${RSYNC_FLAGS}" --strategy "${EXP_STATEGY}" \
            "${SOURCE}" "${DESTINATION}" "${Exclude_List}"
    fi
    rm "${Exclude_List}"
}

read_profile
show_info
create_backup
exit 0
