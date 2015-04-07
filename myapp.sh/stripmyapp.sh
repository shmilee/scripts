#!/usr/bin/env bash

MYAPP="$HOME/myapp"

#-- Options to be used when stripping binaries. See `man strip' for details.
STRIP_BINARIES="--strip-all"
#-- Options to be used when stripping shared libraries. See `man strip' for details.
STRIP_SHARED="--strip-unneeded"
#-- Options to be used when stripping static libraries. See `man strip' for details.
STRIP_STATIC="--strip-debug"

find "$MYAPP" -type f -perm -u+w -print0 2>/dev/null | while read -rd '' binary ; do
    echo "$binary ::"
    case "$(file -bi "$binary")" in
        *application/x-sharedlib*)  # Libraries (.so)
            strip_flags="$STRIP_SHARED";;
        *application/x-archive*)    # Libraries (.a)
            strip_flags="$STRIP_STATIC";;
        *application/x-executable*) # Binaries
            strip_flags="$STRIP_BINARIES";;
        *)
            continue ;;                                                           
    esac
    strip "$binary" ${strip_flags}
done
