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
    local buildir="${WORKDIR}/build/${gituser}-${gitrepo}-${AppCommits[$name]}"
    local distdir="${WORKDIR}/dist/$appdir"

    if [ -d "$distdir" ]; then
        echo "Skip $name: $distdir exists."
        return
    fi

    local downurl="${AppUrls[$name]}/archive/${AppCommits[$name]}.tar.gz"
    local tarball="${WORKDIR}/download/${appdir}.tar.gz"
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
        (
            for pf in ${patchfiles//:/' '};do
                echo "[I] Applying patch file: ${WORKDIR}/patches/$pf"
                patch -p1 -i "${WORKDIR}/patches/$pf" -d "$buildir" 2>&1 || exit 3
            done

            if [ -f "$buildir/src/lib/shortdrama.client.ts" ]; then
                con1=$(grep "User-Agent" "$buildir/src/lib/shortdrama.client.ts")
                con2=$(grep "mode: 'cors'" "$buildir/src/lib/shortdrama.client.ts")
                if [ -n "$con1" -a -n "$con2" ]; then
                    echo -e "\n[I] Fix shortdrama：CORS 的 'Access-Control-Allow-Headers'，不允许使用 'user-agent'"
                    sed -i '/User-Agent/d' "$buildir/src/lib/shortdrama.client.ts"
                fi
            fi

            # ADMIN_USERNAME
            echo -e "\n[I] process.env.USERNAME -> process.env.ADMIN_USERNAME"
            for ts in $(cd "$buildir" && grep 'process.env.USERNAME' -Rl); do
                echo " -> replacing 'process.env.USERNAME' in $ts ..."
                sed -i "s|process.env.USERNAME|process.env.ADMIN_USERNAME|g" "$buildir/$ts"
            done
            for ts in $(cd "$buildir" && grep ' USERNAME' -Rl); do
                echo " -> replacing ' USERNAME' in $ts ..."
                sed -i "s| USERNAME| ADMIN_USERNAME|g" "$buildir/$ts"
            done

            # comment some console.log
            tsfile="src/app/api/admin/theme/route.ts"
            if [ -f "$buildir/$tsfile" ]; then
                if grep "console.log('完整配置对象" "$buildir/$tsfile" >/dev/null; then
                    echo -e "\n[I] //comment log '完整配置对象' in $tsfile"
                    sed -i "s|\(console.log('完整配置对象\)|//\1|" "$buildir/$tsfile"
                fi
            fi
            tsfile="src/app/api/user/my-stats/route.ts"
            if [ -f "$buildir/$tsfile" ]; then
                if grep "console.log('更新用户统计数据" "$buildir/$tsfile" >/dev/null; then
                    echo -e "\n[I] //comment log '更新用户统计数据' in $tsfile"
                    sed -i "s|\(console.log('更新用户统计数据\)|//\1|" "$buildir/$tsfile"
                fi
                if grep "console.log.*my-stats - 开始处理请求" "$buildir/$tsfile" >/dev/null; then
                    echo -e "\n[I] //comment log 'my-stats - 开始处理请求' in $tsfile"
                    sed -i "s|\(console.log.*my-stats - 开始处理请求\)|//\1|" "$buildir/$tsfile"
                fi
            fi
            tsfile="src/lib/downstream.ts"
            if [ -f "$buildir/$tsfile" ]; then
                if grep 'console.log(`\[DEBUG\]' "$buildir/$tsfile" >/dev/null; then
                    echo -e "\n[I] //comment log [DEBUG] in $tsfile"
                    sed -i 's|console.log(`\[DEBUG\]|//console.log(`\[DEBUG\]|' "$buildir/$tsfile"
                fi
            fi

            if [ -f "$buildir/.eslintrc.js" ]; then
                echo -e "\n[I] Ignore no-console Warning ..."
                sed -i "s|'no-console': 'warn'|'no-console': 'off'|" "$buildir/.eslintrc.js"
            fi
        )  2>&1 | tee -a "${WORKDIR}/build/${appdir}-patch.log"
    fi
    # build, test w/ Node.js v24.7.0, Corepack 0.34.0, pnpm 10.15.1
    if [ ! -f "$buildir/.next/standalone/.next/BUILD_ID" ]; then
        printf "\n[I] Building %s in $buildir\n\n" "$name"
        cd "$buildir"
        # 确保 Next.js 在编译时即选择 Node Runtime 而不是 Edge Runtime
        find ./src -type f -name "route.ts" -print0 \
            | xargs -0 sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g"
        (
            # 修复 pnpm lint --fix
            pnpm install --frozen-lockfile && pnpm run build
        ) 2>&1 | tee "${WORKDIR}/build/${appdir}-build.log"
        cd "${WORKDIR}/"
    else
        printf "\n[I] Found builded %s in $buildir\n\n" "$name"
    fi

    # install to $WORKDIR/dist/
    mkdir -pv "$distdir"
    (
        # copy .next/standalone, .next/static, public, scripts, and start.js
        echo "'$buildir/.next/standalone/{*,.*}' -> '$distdir'"
        cp -r "$buildir/.next/standalone/"* "$distdir/"
        cp -r "$buildir/.next/standalone/".* "$distdir/"
        echo "'$buildir/.next/static' -> '$distdir/.next/static'"
        cp -r "$buildir/.next/static" "$distdir/.next/static"
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
    ) 2>&1 | tee "${distdir}-install.log"
    ls "$distdir/node_modules/.pnpm/" \
        | sort >"${distdir}-node_modules.txt"
    ls -l "$distdir/node_modules/" | awk '/^lr/{print $8" -> "$10}' \
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

