#!/bin/bash
# Client in mac os x

_path="$HOME/Library/Synergy"
libfile=/Applications/Synergy.app/Contents/MacOS/plugins/libns.dylib

echo "==> Client for user: $USER"
echo " -> rm old $_path, create new one."
[ -d "$_path" ] && rm -r "$_path"
mkdir -pv "$_path"/{plugins,SSL/Fingerprints}
ln -sv $libfile "$_path"/plugins/libns.dylib
echo " -> add the server FingerPrint"
read -p " -> Input FP:" FFPP
echo $FFPP > "$_path"/SSL/Fingerprints/TrustedServers.txt
echo " -> !! Run command to engoy:"
echo " -> !! \$ /path/to/synergyc -f --enable-crypto <Server IP>"
echo "==> Done."
