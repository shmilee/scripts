#!/bin/bash
# Copyright (C) 2026 shmilee

sleep ${1:-3} # $1 wait for volume

case "$VPN" in
    EasyConnect|EC)
        VPN="EasyConnect"
        VPN_DIR="/usr/share/sangfor/EasyConnect" # EasyConnect deb postinst
        hook_script="hook_EasyConnect.sh"
        ;;
    aTrust|aT)
        VPN="aTrust"
        VPN_DIR="/usr/share/sangfor/aTrust" # aTrust deb postinst
        hook_script="hook_aTrust.sh"
        ;;
    *)
        echo "Error: Unknown VPN type '$VPN'. Please set VPN to EasyConnect/EC or aTrust/aT." >&2
        exit 1
        ;;
esac
if [ ! -d "$VPN_DIR" ]; then
    echo "Error: VPN directory '$VPN_DIR' does not exist." >&2
    echo "  >> Need to bind mount the volume! (-v)!" >&2    
    exit 2
fi
if [ ! -f "$VPN_DIR/$hook_script" ]; then
    echo "Error: Hook script '$hook_script' not found in '$VPN_DIR'." >&2
    exit 3
fi

export VPN VPN_DIR

## add functions & main etc.
echo "Loading $hook_script for VPN: $VPN ..."
source "$VPN_DIR/$hook_script"
main
