#!/usr/bin/env bash
#
# This makes a link $XDG_RUNTIME_DIR/$UID-Xauthority to XAUTHORITY.
#
# Put this in directory /etc/X11/xinit/xinitrc.d/
# (man sddm.conf, SessionCommand=/usr/share/sddm/scripts/Xsession)
#
# Why?
# As sddm creates XAUTHORITY=/tmp/xauth_XXXXX (man sddm.conf, UserAuthFile),
# but we need a static XAUTHORITY path for screenlock.
#
# See more:
#   https://unix.stackexchange.com/questions/577139
#   https://github.com/google/xsecurelock/issues/183
#   https://bbs.archlinux.org/viewtopic.php?id=288986

if [ -n "${XAUTHORITY}" ]; then
    if [ -d "${XDG_RUNTIME_DIR}" ]; then
        ln -sf "${XAUTHORITY}" "${XDG_RUNTIME_DIR}/${UID}-Xauthority"
    fi
fi
