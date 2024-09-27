#!/bin/bash

if [ -d ~/.config/QQ/versions ]; then
	find ~/.config/QQ/versions -name sharp-lib -type d -exec rm -r {} \; 2>/dev/null
fi

rm -rf ~/.config/QQ/crash_files/*

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}

if [[ -f "${XDG_CONFIG_HOME}/qq-flags.conf" ]]; then
	mapfile -t QQ_USER_FLAGS <<<"$(grep -v '^#' "${XDG_CONFIG_HOME}/qq-flags.conf")"
	echo "User flags:" ${QQ_USER_FLAGS[@]}
fi

# set default LITELOADERQQNT_PROFILE for LiteLoaderQQNT data plugins
LITELOADERQQNT_PROFILE=${LITELOADERQQNT_PROFILE:-~/.config/LiteLoaderQQNT}
export LITELOADERQQNT_PROFILE

exec /opt/QQ/qq ${QQ_USER_FLAGS[@]} "$@"
