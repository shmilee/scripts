#!/bin/bash
# Copyright (C) 2025 shmilee

export DOCKER_ENV=false
WORKDIR="$(dirname $(readlink -f "$0"))"
source "$WORKDIR/github-repos.conf"
mkdir -pv "$WORKDIR"/{download,build,dist/{config-collections,next-cache}}

build_app() {
    local name="$1"
    local gituser="$(get_gituser $name)"
    local gitrepo="$(get_gitrepo $name)"
    local appdir="$(get_appdir $name)"
    local buildir="${WORKDIR}/build/$appdir"
    local distdir="${WORKDIR}/dist/$appdir"

    if [ -d "$distdir" ]; then
        echo "Skip $name: $distdir exists."
        return
    fi

    local downurl="${AppUrls[$name]}/archive/${AppCommits[$name]}.tar.gz"
    local tarball="${WORKDIR}/download/$(get_tarball $name)"
    if [ ! -f "$tarball" ]; then
        echo "=> download: $tarball"
        $CURLCMD -o "$tarball" "$downurl" || return
        # rm screenshotX.png
        gzip -d "$tarball"
        tar -v -f "${tarball/.gz/}" --delete ${gitrepo}-${AppCommits[$name]}/public/screenshot{1,2,3}.png
        if [ "$gitrepo" == 'KatelyaTV' -o "$gitrepo" == 'DecoTV' ]; then
            tar -v -f "${tarball/.gz/}" --delete ${gitrepo}-${AppCommits[$name]}/public/{screenshot4.png,wechat.jpg}
        fi
        gzip "${tarball/.gz/}"
    fi

    if [ ! -d "$buildir" ]; then
        tar zxf "$tarball" -C "${WORKDIR}/build/"
        mv -v "${WORKDIR}/build/${gitrepo}-${AppCommits[$name]}" "$buildir"
        # patch files in dir patches/
        local patchfiles="${AppPatches[$name]}"
        echo >"${WORKDIR}/build/${appdir}-patch.log"
        {
            for pf in ${patchfiles//:/' '}; do
                case "$pf" in
                    *.patch)
                        echo -e "\n[I] Applying patch file: ${WORKDIR}/patches/$pf"
                        patch -p1 -i "${WORKDIR}/patches/$pf" -d "$buildir" 2>&1 || exit 3
                        ;;
                    *.patch.sh)
                        echo -e "\n[I] Running patch script file: ${WORKDIR}/patches/$pf"
                        bash "${WORKDIR}/patches/$pf" "$name" "$buildir" 2>&1 || exit 3
                        ;;
                    *)
                        echo "NOT a '.patch' or '.patch.sh' file!"
                        ;;
                esac
            done
        }  2>&1 | tee -a "${WORKDIR}/build/${appdir}-patch.log"
    fi
    # build, test w/ Node.js v24.7.0, Corepack 0.34.0, pnpm 10.15.1
    if [ ! -f "$buildir/.next/standalone/.next/BUILD_ID" ]; then
        printf "\n[I] Building %s in $buildir\n\n" "$name"
        cd "$buildir"
        # 确保 Next.js 在编译时即选择 Node Runtime 而不是 Edge Runtime
        find ./src -type f -name "route.ts" -print0 \
            | xargs -0 sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g"
        {
            # 修复 pnpm lint --fix
            pnpm install --frozen-lockfile && pnpm run build
        } 2>&1 | tee "${WORKDIR}/build/${appdir}-build.log"
        cd "${WORKDIR}/"
    else
        printf "\n[I] Found builded %s in $buildir\n\n" "$name"
    fi

    # install to $WORKDIR/dist/
    mkdir -pv "$distdir"
    {
        # copy .next/standalone, .next/static, public, scripts, and start.js
        echo "'$buildir/.next/standalone/{*,.*}' -> '$distdir'"
        cp -r "$buildir/.next/standalone/"* "$distdir/"
        cp -r "$buildir/.next/standalone/".* "$distdir/"
        echo "'$buildir/.next/static' -> '$distdir/.next/static'"
        cp -r "$buildir/.next/static" "$distdir/.next/static"
        if [ -d "$distdir/public" ]; then
            rm -rv "$distdir/public"
        fi
        cp -rv "$buildir/public" "$distdir/public"
        cp -rv "$buildir/scripts" "$distdir/scripts"
        cp -v "$buildir/start.js" "$distdir/start.js"
        # link manifest.json
        mv -v "$distdir/public/manifest.json" \
            "${distdir}-manifest.json"
        ln -sv ../../"${appdir}-manifest.json" \
            "$distdir/public/manifest.json"
        # link .next/cache dir
        ln -sv ../../next-cache "${distdir}/.next/cache"
        # link config-collections/{moontv,iptv}
        ln -sv ../../config-collections "$distdir/public/config-collections"
        printf "\n[I] %s installed to ${distdir}\n\n" "$name"
    } 2>&1 | tee "${distdir}-install.log"
    ls "$distdir/node_modules/.pnpm/" \
        | sort >"${distdir}-node_modules.txt"
    # awk NF 总字段数
    ls -l "$distdir/node_modules/" | awk '/^lr/{print $(NF-2)" -> "$NF}' \
        | sort >>"${distdir}-node_modules.txt"

    # squashfs compress
    local appsqfs="${distdir}.squashfs"
    local modsqfs="${WORKDIR}/dist/$(get_nodemodsquashfs $name)"
    local mksqfsopts="-comp zstd -all-root"
    mksquashfs "${distdir}" "$appsqfs" $mksqfsopts \
        -e "$distdir/node_modules" 2>&1 | tee -a "${distdir}-install.log"
    local excludepat="$(get_nodemodsexclude $name)"
    local excludelist="${distdir}-node_modules-exclude.txt"
    if [ -n "$excludepat" ]; then
        grep -E "$excludepat" "${distdir}-node_modules.txt" \
            | sed "s|^|${distdir}/node_modules/.pnpm/|" >"$excludelist"
    else
        echo >"$excludelist"
    fi
    mksquashfs "${distdir}/node_modules" "$modsqfs" $mksqfsopts \
        -ef "$excludelist" 2>&1 | tee -a "${distdir}-install.log"

    # check files
    cd "${WORKDIR}/dist/"
    find $appdir -maxdepth 2
    echo
    cd "${WORKDIR}/"
}

echo "=== ${AppNames[@]} ==="
for name in ${AppNames[@]}; do
    build_app "$name"
done

if [ -n "$ConfigCollectionsProxy" ]; then
    curl_cmd="curl -L --proxy $ConfigCollectionsProxy"
else
    curl_cmd="curl -L"
fi
for conf in ${!ConfigCollections[@]}; do
    echo "=> download: config-collections/$conf"
    echo $CURLCMD "${ConfigCollections[$conf]}"
    $CURLCMD -o "$WORKDIR/dist/config-collections/$conf" "${ConfigCollections[$conf]}"
done

