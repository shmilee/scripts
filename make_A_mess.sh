#!/bin/bash
# touch file, write file, create directory, delete directory ... , do all I can do where I have the permission.

usage() {
    cat <<EOF
$0 [option] target_PATH1 [PATH2] ...
eg. \$ $0 -L /tmp /sys
    \$ $0 /tmp

Option:
    -L,--log    Log all the process
EOF
}

if [ x"$1" == x ]; then
    echo "!? => Nothing?! Kidding me? I will make the '/' as target! "
elif [ x"$1" == x"-L" -o x"$1" == x"--log" ]; then
    echo "!? => I promise all will be LOGGED!"
    echo "!? => Trust ME! GOOD LUCK for U! ^_^"
else
    echo "!? => Thanks for your test! "
fi
