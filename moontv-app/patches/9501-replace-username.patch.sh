#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

# ADMIN_USERNAME
echo "[I] process.env.USERNAME -> process.env.ADMIN_USERNAME"
for ts in $(cd "$buildir" && grep 'process.env.USERNAME' -Rl); do
    echo " -> replacing 'process.env.USERNAME' in $ts ..."
    sed -i "s|process.env.USERNAME|process.env.ADMIN_USERNAME|g" "$buildir/$ts"
done

echo "[I] USERNAME -> ADMIN_USERNAME"
for ts in $(cd "$buildir" && grep ' USERNAME' -Rl); do
    echo " -> replacing ' USERNAME' in $ts ..."
    sed -i "s| USERNAME| ADMIN_USERNAME|g" "$buildir/$ts"
done
